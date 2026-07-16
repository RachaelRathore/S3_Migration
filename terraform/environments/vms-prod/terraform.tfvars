project_id = "vms-prod-501607"
region     = "asia-south1"

buckets = {
  "atlas-prod-aps1-email-ingestion" = {
    versioning    = true
    public_access = false
  }
  "prod-atlas-backup-mumbai" = {
    versioning    = true
    public_access = false
  }
}
