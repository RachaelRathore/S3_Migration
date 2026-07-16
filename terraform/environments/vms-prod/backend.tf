terraform {
  backend "gcs" {
    bucket = "vms-prod-501607-tfstate"
    prefix = "terraform/state/s3-migration"
  }
}
