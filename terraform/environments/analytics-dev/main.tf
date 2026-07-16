# ---- S3 -> GCS bucket migration ----
module "bucket_lifecycle" {
  source = "../../modules/buckets/lifecycle"

  buckets = keys(var.buckets)

  nearline_after_days          = 30
  coldline_after_days          = 90
  archive_after_days           = null
  delete_after_days            = 180
  delete_noncurrent_after_days = 14
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
