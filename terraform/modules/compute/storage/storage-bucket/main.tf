# Enable the Storage API in this project (safe if already enabled -
# disable_on_destroy = false means Terraform never turns it back off).
resource "google_project_service" "storage" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# One GCS bucket per entry in var.buckets, migrated 1:1 from AWS S3.
#
# Migration policy: every bucket is created in asia-south1, full stop -
# hardcoded here, not driven by a variable, so it can never be
# overridden via -var/TF_VAR_region/tfvars. This applies even to the
# source S3 buckets that live outside ap-south-1 (bulk-policy-migration-
# 070532166964 in us-east-1, ff-adhoc-sparrow-data in us-east-2) - their
# original AWS region has no bearing on the GCS destination location.
resource "google_storage_bucket" "this" {
  for_each = var.buckets

  name     = each.key
  project  = var.project_id
  location = "asia-south1"

  storage_class                = "STANDARD"
  uniform_bucket_level_access  = true
  force_destroy                = var.force_destroy
  public_access_prevention     = each.value.public_access ? "inherited" : "enforced"

  versioning {
    enabled = each.value.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = lookup(var.lifecycle_rules, each.key, [])

    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = try(lifecycle_rule.value.action.storage_class, null)
      }
      condition {
        age                   = try(lifecycle_rule.value.condition.age, null)
        created_before        = try(lifecycle_rule.value.condition.created_before, null)
        with_state            = try(lifecycle_rule.value.condition.with_state, null)
        matches_storage_class = try(lifecycle_rule.value.condition.matches_storage_class, null)
        num_newer_versions    = try(lifecycle_rule.value.condition.num_newer_versions, null)
      }
    }
  }

  labels = merge(
    {
      migrated-from = "aws-s3"
      managed-by    = "terraform"
    },
    each.value.labels
  )

  depends_on = [google_project_service.storage]
}
