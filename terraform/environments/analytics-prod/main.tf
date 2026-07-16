# ---- S3 -> GCS bucket migration ----
module "bucket_lifecycle" {
  source = "../../modules/buckets/lifecycle"

  buckets = keys(var.buckets)

  nearline_after_days          = 30
  coldline_after_days          = 90
  archive_after_days           = 365
  delete_after_days            = null
  delete_noncurrent_after_days = 30

  # datazip-backup-freightfox is flagged "backup_folder_tiering" in the
  # mapping sheet - tier it down to cold storage much faster than the
  # rest of this project's buckets.
  overrides = {
    "datazip-backup-freightfox" = {
      nearline_after_days = 7
      coldline_after_days = 30
    }
  }
}

module "storage_buckets" {
  source = "../../modules/buckets/storage-bucket"

  project_id      = var.project_id
  buckets         = var.buckets
  lifecycle_rules = module.bucket_lifecycle.lifecycle_rules
}

module "storage_transfer" {
  source = "../../modules/buckets/transfer"

  project_id             = var.project_id
  bucket_names           = module.storage_buckets.bucket_names
  enable_transfer        = var.enable_transfer
  aws_access_key_id      = var.aws_access_key_id
  aws_secret_access_key  = var.aws_secret_access_key
}
