terraform {
  backend "gcs" {
    bucket = "tms-prod-501607-tfstate"
    prefix = "terraform/state/s3-migration"
  }
}
