terraform {
  backend "gcs" {
    bucket = "tms-dev-501607-tfstate"
    prefix = "terraform/state/s3-migration"
  }
}
