variable "project_name" {
    description = "The name of the project"
    type = string
    default = "Pipeline"
}

variable "environment" {
    description = "The environment to deploy to"
    type = string
    default = "dev"
}

variable "tags" {
    description = "A map of tags to apply to all resources"
    type = map(string)
    default = {}
  
}

variable "source_arn" {
    description = "ARN Kinesis source"
    type = string
  
}
