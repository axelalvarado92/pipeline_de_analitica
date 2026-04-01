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