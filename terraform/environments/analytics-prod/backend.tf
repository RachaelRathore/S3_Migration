terraform {
  backend "gcs" {
    bucket = "analytics-prod-501608-tfstate"
    prefix = "terraform/state/s3-migration"
  }
}
