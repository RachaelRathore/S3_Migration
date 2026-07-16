project_id = "tms-dev-501607"
region     = "asia-south1"

buckets = {
  "ff-dev-alb-logs" = {
    versioning    = true
    public_access = false
  }
  "kannan-ff-codebuild-bucket" = {
    versioning    = true
    public_access = false
  }
  "mumbai-ffox-tsp-onboarding-documents-v1-poc" = {
    versioning    = true
    public_access = false
  }
}
