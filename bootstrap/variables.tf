variable "bucket_name" {
  description = "Globally unique Object Storage bucket name for Terraform state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 chars of lowercase letters, digits, dots and hyphens."
  }
}

variable "bucket_max_size" {
  description = "Bucket size limit in bytes"
  type        = number
  default     = 104857600 # 100 MiB
}

variable "labels" {
  description = "Tags for the bucket"
  type        = map(string)
  default = {
    project    = "pet"
    managed_by = "terraform"
  }
}
