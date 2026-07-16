variable "buckets" {
  description = "Bucket names this policy applies to. Usually keys(var.buckets) from the calling environment."
  type        = list(string)
}

variable "nearline_after_days" {
  description = "Transition objects to NEARLINE after this many days. Set to null to disable."
  type        = number
  default     = 30
}

variable "coldline_after_days" {
  description = "Transition objects to COLDLINE after this many days. Set to null to disable."
  type        = number
  default     = 90
}

variable "archive_after_days" {
  description = "Transition objects to ARCHIVE after this many days. Set to null to disable."
  type        = number
  default     = 365
}

variable "delete_after_days" {
  description = "Delete objects entirely after this many days. Set to null to keep indefinitely."
  type        = number
  default     = null
}

variable "delete_noncurrent_after_days" {
  description = "For versioned buckets, delete noncurrent (superseded) versions after this many days. Set to null to disable."
  type        = number
  default     = 30
}

variable "overrides" {
  description = "Per-bucket overrides of the defaults above, keyed by bucket name. Any field omitted falls back to the environment default."
  type = map(object({
    nearline_after_days          = optional(number)
    coldline_after_days          = optional(number)
    archive_after_days           = optional(number)
    delete_after_days            = optional(number)
    delete_noncurrent_after_days = optional(number)
  }))
  default = {}
}
