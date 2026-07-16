terraform {
  backend "gcs" {
    bucket = "tms-staging-501607-tfstate"
    prefix = "terraform/state/s3-migration"
  }
}
