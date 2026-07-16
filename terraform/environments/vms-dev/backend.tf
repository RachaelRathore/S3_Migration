terraform {
  backend "gcs" {
    bucket = "vms-dev-501607-tfstate"
    prefix = "terraform/state/s3-migration"
  }
}
