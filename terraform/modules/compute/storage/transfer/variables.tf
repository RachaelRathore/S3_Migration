variable "project_id" {
  description = "The GCP Project ID that owns the destination buckets"
  type        = string
}

variable "bucket_names" {
  description = "Map of source S3 bucket name => destination GCS bucket name. Normally module.storage_buckets.bucket_names."
  type        = map(string)
  default     = {}
}

variable "enable_transfer" {
  description = "Set true to create the S3 -> GCS Storage Transfer jobs. Kept false by default so a routine bucket apply never touches data."
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "AWS access key ID for a read-only IAM user with s3:GetObject/s3:ListBucket on the source buckets. This is consumed directly by the google_storage_transfer_job resource - Terraform's own AWS access does not require a separate 'aws' provider block. Supply via TF_VAR_aws_access_key_id, never commit."
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "Matching AWS secret access key. Supply via TF_VAR_aws_secret_access_key, never commit."
  type        = string
  default     = ""
  sensitive   = true
}

variable "transfer_delete_from_source" {
  description = "If true, STS deletes objects from the S3 source once copied to GCS. Leave false until the migration is validated."
  type        = bool
  default     = false
}
