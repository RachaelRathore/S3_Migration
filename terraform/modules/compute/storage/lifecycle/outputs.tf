output "lifecycle_rules" {
  description = "Map of bucket_name => list of lifecycle_rule objects. Pass into module.storage_buckets.lifecycle_rules."
  value       = local.rules
}
