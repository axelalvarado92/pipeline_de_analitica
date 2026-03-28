variable "tags" {
    description = "Tags for glue"
    type = map(string)
    default = {}
  
}
variable "project_name" {
    description = "Project name"
    type = string
    default = "pipeline"
  
}
variable "environment" {
    description = "Project environment"
    type = string
    default = "dev"
  
}

variable "bucket_arn" {
    description = "Data lake bucket arn"
    type = string
  
}

variable "s3_target" {
    description = "S3 target path"
    type = string
  
}

