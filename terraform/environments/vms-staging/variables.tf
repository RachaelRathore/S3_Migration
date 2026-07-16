variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The GCP region used for the provider default and bootstrap resources. Bucket LOCATION itself is hardcoded to asia-south1 in modules/buckets/storage-bucket regardless of this value."
  type        = string
  default     = "asia-south1"
}

# ---- S3 -> GCS bucket migration ----
variable "buckets" {
  description = "Map of S3-migrated bucket_name => { versioning, public_access } for buckets belonging to this project. Populated in terraform.tfvars from the AWS -> GCP mapping sheet."
  type = map(object({
    versioning    = bool
    public_access = bool
  }))
  default = {}
}

variable "enable_transfer" {
  description = "Set true (via -var or TF_VAR_enable_transfer) to create the S3 -> GCS Storage Transfer jobs for this environment's buckets. Left false by default so a routine bucket apply never touches data."
  type        = bool
  default     = false
}

# AWS credentials: consumed directly by modules/buckets/transfer's
# google_storage_transfer_job resource so GCP can read from S3. Supply via
# TF_VAR_aws_access_key_id / TF_VAR_aws_secret_access_key (CircleCI env
# vars) - never put real values in terraform.tfvars.
variable "aws_access_key_id" {
  description = "AWS access key ID for the read-only migration IAM user."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "Matching AWS secret access key."
  type        = string
  default     = ""
  sensitive   = true
}
