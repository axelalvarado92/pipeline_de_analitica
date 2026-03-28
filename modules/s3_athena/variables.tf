variable "bucket_name" {
    description = "The name of the S3 bucket"
    type = string
}

variable "tags" {
    description = "A map of tags to add to all resources"
    type = map(string)
    default = {}
}

variable "kms_key_arn" {
    description = "The ARN of the KMS key to use for encryption"
    type = string
  
}