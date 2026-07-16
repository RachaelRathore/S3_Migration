variable "project_id" {
  description = "The GCP Project ID that owns these buckets"
  type        = string
}

variable "buckets" {
  description = "Map of bucket_name => { versioning, public_access, labels }. Every key is created as a GCS bucket of the same name."
  type = map(object({
    versioning    = bool
    public_access = bool
    labels        = optional(map(string), {})
  }))
  default = {}
}

variable "lifecycle_rules" {
  description = "Map of bucket_name => list of lifecycle_rule objects. Normally passed in from module.bucket_lifecycle.lifecycle_rules."
  type = map(list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                   = optional(number)
      created_before        = optional(string)
      with_state            = optional(string)
      matches_storage_class = optional(list(string))
      num_newer_versions    = optional(number)
    })
  })))
  default = {}
}

variable "force_destroy" {
  description = "If true, allows terraform destroy to delete non-empty buckets. Keep false outside sandboxes."
  type        = bool
  default     = false
}
