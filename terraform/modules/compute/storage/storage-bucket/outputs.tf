output "bucket_names" {
  description = "Map of bucket_name => actual created GCS bucket name (1:1 with the source S3 name)."
  value       = { for k, b in google_storage_bucket.this : k => b.name }
}

output "bucket_urls" {
  value = { for k, b in google_storage_bucket.this : k => b.url }
}

output "bucket_self_links" {
  value = { for k, b in google_storage_bucket.this : k => b.self_link }
}
