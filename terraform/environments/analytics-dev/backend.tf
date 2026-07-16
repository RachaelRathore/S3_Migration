terraform {
  backend "gcs" {
    bucket = "analytics-dev-501608-tfstate"
    prefix = "terraform/state/s3-migration"
  }
}
