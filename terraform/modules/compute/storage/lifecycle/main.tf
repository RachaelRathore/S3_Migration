locals {
  effective = {
    for name in var.buckets : name => {
      nearline_after_days          = try(var.overrides[name].nearline_after_days, var.nearline_after_days)
      coldline_after_days          = try(var.overrides[name].coldline_after_days, var.coldline_after_days)
      archive_after_days           = try(var.overrides[name].archive_after_days, var.archive_after_days)
      delete_after_days            = try(var.overrides[name].delete_after_days, var.delete_after_days)
      delete_noncurrent_after_days = try(var.overrides[name].delete_noncurrent_after_days, var.delete_noncurrent_after_days)
    }
  }

  rules = {
    for name, p in local.effective : name => concat(
      p.nearline_after_days == null ? [] : [{
        action    = { type = "SetStorageClass", storage_class = "NEARLINE" }
        condition = { age = p.nearline_after_days, matches_storage_class = ["STANDARD"] }
      }],
      p.coldline_after_days == null ? [] : [{
        action    = { type = "SetStorageClass", storage_class = "COLDLINE" }
        condition = { age = p.coldline_after_days, matches_storage_class = ["NEARLINE", "STANDARD"] }
      }],
      p.archive_after_days == null ? [] : [{
        action    = { type = "SetStorageClass", storage_class = "ARCHIVE" }
        condition = { age = p.archive_after_days, matches_storage_class = ["COLDLINE", "NEARLINE", "STANDARD"] }
      }],
      p.delete_after_days == null ? [] : [{
        action    = { type = "Delete" }
        condition = { age = p.delete_after_days }
      }],
      p.delete_noncurrent_after_days == null ? [] : [{
        action    = { type = "Delete" }
        condition = { age = p.delete_noncurrent_after_days, with_state = "ARCHIVED" }
      }]
    )
  }
}
