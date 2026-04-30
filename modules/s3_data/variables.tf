variable "bucket_name" {
    description = "The name of the S3 bucket"
    type = string
  
}

variable "tags" {
    description = "A map of tags to add to all resources"
    type = map(string)
  
}

variable "lambda_trigger_arn" {
  type = string
}

variable "kms_key_arn" {
    description = "ARN of kms key"
    type = string
  
}

variable "data_prefix" {
    description = "Prefix for log files"
    type = string
  
}