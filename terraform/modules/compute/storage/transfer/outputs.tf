output "transfer_job_names" {
  description = "Map of source S3 bucket name => Storage Transfer job resource name."
  value       = { for k, j in google_storage_transfer_job.s3_to_gcs : k => j.name }
}
