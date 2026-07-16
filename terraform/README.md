# AWS S3 -> GCP Cloud Storage Migration - Terraform

Creates GCS buckets (1:1 with the source AWS S3 buckets) across all 8
FreightFox GCP projects, and optionally runs the S3 -> GCS data copy via
Storage Transfer Service. Bucket names, versioning, and public/private
status are pulled directly from the AWS -> GCP mapping sheet and
committed in each environment's `terraform.tfvars`.

## Layout

```
terraform/
  modules/buckets/
    storage-bucket/   # google_storage_bucket resources (hardcoded to asia-south1)
    lifecycle/         # turns day-count knobs into lifecycle_rule blocks
    transfer/           # S3 -> GCS Storage Transfer jobs (needs AWS creds), gated by var.enable_transfer
  environments/
    analytics-dev/   analytics-prod/
    tms-dev/          tms-staging/        tms-prod/
    vms-dev/          vms-staging/        vms-prod/
      backend.tf        # remote state: gs://<project_id>-tfstate/terraform/state/s3-migration
      versions.tf
      provider.tf
      variables.tf
      main.tf
      terraform.tfvars  # project_id, region, and the real bucket list for this project
      outputs.tf
  .gitignore
  README.md
```

## Buckets per project (from the mapping sheet)

| Environment | Project ID | Buckets |
|---|---|---|
| analytics-dev | analytics-dev-501608 | 1 |
| analytics-prod | analytics-prod-501608 | 9 |
| tms-dev | tms-dev-501607 | 3 |
| tms-prod | tms-prod-501607 | 17 |
| tms-staging | tms-staging-501607 | 1 |
| vms-dev | vms-dev-501607 | 1 |
| vms-prod | vms-prod-501607 | 2 |
| vms-staging | vms-staging-501607 | 0 - no buckets mapped yet; confirm with the mapping sheet owner whether that's expected |

33 buckets total. Full per-bucket detail (versioning, public/private) is
in each environment's `terraform.tfvars`.

## Region policy

Every bucket is created in `asia-south1`. This is hardcoded in
`modules/buckets/storage-bucket/main.tf`, not driven by `var.region` -
so it can't be changed via `-var`/tfvars, regardless of which AWS
region the source bucket actually lives in (most are `ap-south-1`, a
couple are `us-east-1`/`us-east-2`).

## AWS + GCP access - what's actually required

- **GCP**: the `google` provider needs credentials with `roles/storage.admin`
  and `roles/serviceusage.serviceUsageAdmin` on the relevant project -
  either `gcloud auth application-default login` locally, or a service
  account key via `GOOGLE_APPLICATION_CREDENTIALS` in CI.
- **AWS**: no separate Terraform `aws` provider is used or required. AWS
  access is needed only for `modules/buckets/transfer`, where a plain
  access key/secret pair is passed straight into the
  `google_storage_transfer_job` resource's `aws_access_key` block -
  that's how GCP's Storage Transfer Service authenticates *to* AWS to
  read the source objects. Supply these as `TF_VAR_aws_access_key_id` /
  `TF_VAR_aws_secret_access_key`, sourced from a read-only IAM user
  scoped to `s3:GetObject`, `s3:ListBucket`, `s3:GetBucketLocation` on
  the 33 source buckets (add `s3:GetObjectVersion` too, since all but
  one bucket has versioning enabled).

Until both are set, `terraform apply` will happily create the GCS
buckets (GCP-only), but any run with `enable_transfer = true` will fail
- Storage Transfer jobs need working AWS credentials to actually move
  data.

## Step-by-step: get this live

### 1. Prepare GCP
For each of the 8 projects, create its Terraform state bucket if it
doesn't already exist (name must match each environment's `backend.tf`):
```bash
gsutil mb -l asia-south1 gs://tms-dev-501607-tfstate
gsutil mb -l asia-south1 gs://tms-prod-501607-tfstate
# ...repeat for all 8 projects
```
Create (or reuse) a GCP service account with `roles/storage.admin` and
`roles/serviceusage.serviceUsageAdmin` on all 8 projects, and download
its JSON key. Base64-encode it - you'll paste this into CircleCI:
```bash
base64 -i migration-sa-key.json | tr -d '\n' > migration-sa-key.b64
```

### 2. Prepare AWS
Create a dedicated, read-only IAM user (e.g. `gcp-storage-transfer`)
with a policy scoped to the 33 source buckets:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket", "s3:GetBucketLocation"],
    "Resource": ["arn:aws:s3:::BUCKET-NAME", "arn:aws:s3:::BUCKET-NAME/*"]
  }]
}
```
Generate an access key/secret for this user. Keep both handy for step 4.

### 3. Push this repo to GitHub
```bash
cd terraform
git init
git add .
git commit -m "S3 to GCS bucket migration - Terraform"
git branch -M main
git remote add origin https://github.com/<your-org>/<your-repo>.git
git push -u origin main
```

### 4. Wire credentials into CircleCI
Since your `config.yml` is already in place, it needs these available -
add them as **Project Environment Variables** or, better, in a
**Context** (e.g. `freightfox-migration`) that the pipeline's jobs
reference:
- `GCLOUD_SERVICE_KEY` - the base64 string from step 1.
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - from step 2. Your
  pipeline should export these as `TF_VAR_aws_access_key_id` /
  `TF_VAR_aws_secret_access_key` before running `terraform plan`/`apply`
  (Terraform doesn't read `AWS_ACCESS_KEY_ID` automatically for a plain
  input variable - only an actual `aws` provider would; since this repo
  doesn't use one, the names need to be mapped to `TF_VAR_*` explicitly
  in a run step, e.g.:
  ```bash
  export TF_VAR_aws_access_key_id="$AWS_ACCESS_KEY_ID"
  export TF_VAR_aws_secret_access_key="$AWS_SECRET_ACCESS_KEY"
  ```
- In your pipeline's GCP auth step, decode `GCLOUD_SERVICE_KEY` and set
  `GOOGLE_APPLICATION_CREDENTIALS` to point at it before any
  `terraform init`/`plan`/`apply`.

### 5. First run - buckets only
Trigger the pipeline (push to `main`, or however your `config.yml` is
set to fire). Since `enable_transfer` defaults to `false`, the first
apply will only create the 33 GCS buckets across the 7 projects that
have buckets mapped - no data moves yet.

### 6. Second run - turn on data transfer
Once buckets exist and you've verified AWS credentials are wired in,
re-run with `enable_transfer=true` (either as a pipeline parameter, a
manual `-var` override, or a dedicated workflow step in your
`config.yml`) to create the Storage Transfer jobs and start the S3 -> GCS
copy.

### 7. Validate and cut over
See the migration strategy doc from earlier in this project for the
full pre-flight / cutover / rollback checklist.

## Running manually (without CircleCI)

```bash
cd environments/tms-dev
terraform init
terraform plan
terraform apply

# Later, to start data transfer:
export TF_VAR_aws_access_key_id="..."
export TF_VAR_aws_secret_access_key="..."
terraform plan -var="enable_transfer=true"
terraform apply -var="enable_transfer=true"
```
