variable "s3_bucket" {
    description = "Athena s3 bucket"
    type = string
  
}

variable "kms_key_athena" {
    description = "Athena kms key arn"
    type = string
  
}

variable "project_name" {
    description = "Project name"
    type = string
    default = "pipeline"
}

variable "environment" {
    description = "Environment"
    type = string
    default = "dev"
  
}