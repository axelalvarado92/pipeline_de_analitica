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

variable "filename" {
    description = "The path to the lambda function zip file"
    type = string
}

variable "function_name" {
    description = "The name of the lambda function"
    type = string
}

variable "handler" {
    description = "The handler for the lambda function"
    type = string
}

variable "timeout" {
    description = "The timeout for the lambda function"
    type = number
    default = 30
}

variable "memory_size" {
    description = "The memory size for the lambda function"
    type = number
}

variable "environment_variables" {
    description = "The environment variables for the lambda function"
    type = map(string)
    default = {}
  
}

variable "kinesis_arns" {
    description = "The arns of the kinesis streams"
    type = list(string)
  
}

variable "source_code_hash" {
    description = "Used to trigger updates"
    type = string
  
}

variable "kms_key_arn" {
    description = "The arn of the kms key"
    type = string
  
}

variable "bucket_arn" {
    description = "The arn of the bucket"
    type = string
  
}