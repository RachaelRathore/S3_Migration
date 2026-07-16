output "s3_migrated_bucket_names" {
  description = "Map of source S3 bucket name => created GCS bucket name."
  value       = module.storage_buckets.bucket_names
}

output "s3_migrated_bucket_urls" {
  description = "Map of source S3 bucket name => GCS bucket URL."
  value       = module.storage_buckets.bucket_urls
}

output "transfer_job_names" {
  description = "Map of source S3 bucket name => Storage Transfer job name (empty unless enable_transfer = true)."
  value       = module.storage_transfer.transfer_job_names
}
