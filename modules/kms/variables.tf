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

variable "sources_arns" {
    description = "ARN Kinesis source"
    type = list(string)
    default = []
  
}

variable "prefix" {
    description = "the name of prefix for resources"
    type = string
}

variable "lambda_role_arn" {
    description = "ARN del rol de Lambda"
    type = string
    default = "null"
}