# Phase 2 of the migration: copy actual object data from AWS S3 into the
# GCS buckets created by modules/buckets/storage-bucket. This is the part
# of the pipeline that genuinely needs AWS access - the
# google_storage_transfer_job resource below reads var.aws_access_key_id
# / var.aws_secret_access_key directly and uses them to call the AWS S3
# API on GCP's behalf. Entirely gated behind var.enable_transfer so it
# never fires as a side effect of a normal bucket-config apply.

resource "google_project_service" "storagetransfer" {
  count = var.enable_transfer ? 1 : 0

  project            = var.project_id
  service            = "storagetransfer.googleapis.com"
  disable_on_destroy = false
}

# STS provisions a per-project service account on first use. Look it up
# so we can grant it write access to the destination buckets.
data "google_storage_transfer_project_service_account" "default" {
  count = var.enable_transfer ? 1 : 0

  project = var.project_id
}

resource "google_storage_bucket_iam_member" "transfer_sa_write" {
  for_each = var.enable_transfer ? var.bucket_names : {}

  bucket = each.value
  role   = "roles/storage.admin"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.default[0].email}"

  depends_on = [google_project_service.storagetransfer]
}

resource "google_storage_transfer_job" "s3_to_gcs" {
  for_each = var.enable_transfer ? var.bucket_names : {}

  project     = var.project_id
  description = "AWS S3 (${each.key}) -> GCS (${each.value}) migration"
  status      = "ENABLED"

  transfer_spec {
    aws_s3_data_source {
      bucket_name = each.key

      aws_access_key {
        access_key_id     = var.aws_access_key_id
        secret_access_key = var.aws_secret_access_key
      }
    }

    gcs_data_sink {
      bucket_name = each.value
    }

    transfer_options {
      overwrite_objects_already_existing_in_sink = true
      delete_objects_unique_in_sink              = false
      delete_objects_from_source_after_transfer  = var.transfer_delete_from_source
    }
  }

  schedule {
    schedule_start_date {
      year  = tonumber(formatdate("YYYY", timestamp()))
      month = tonumber(formatdate("MM", timestamp()))
      day   = tonumber(formatdate("DD", timestamp()))
    }
    # Daily re-sync until cutover. Remove this block for a strict one-time copy.
    repeat_interval = "86400s"
  }

  depends_on = [google_storage_bucket_iam_member.transfer_sa_write]
}
