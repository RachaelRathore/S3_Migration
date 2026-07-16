terraform {
  backend "gcs" {
    bucket = "vms-staging-501607-tfstate"
    prefix = "terraform/state/s3-migration"
  }
}
