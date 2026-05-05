variable "bucket_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "force_destroy" {
  type    = bool
  default = true
}

# versioning
variable "enable_versioning" {
  type    = bool
  default = false
}

# logging
variable "enable_logging" {
  type    = bool
  default = false
}

variable "log_bucket" {
  type    = string
  default = null
}

variable "log_prefix" {
  type    = string
  default = ""
}

# lifecycle
variable "enable_lifecycle" {
  type    = bool
  default = false
}

variable "lifecycle_expiration_days" {
  type    = number
  default = 7
}

variable "lifecycle_noncurrent_days" {
  type    = number
  default = 30
}

# notifications
variable "enable_notifications" {
  type    = bool
  default = false
}

variable "lambda_arn" {
  type    = string
  default = null
}

variable "filter_prefix" {
  type    = string
  default = ""
}

variable "lambda_permission_dependency" {
  type = any
  default = null
}

variable "enable_athena_access" {
  type    = bool
  default = false
}