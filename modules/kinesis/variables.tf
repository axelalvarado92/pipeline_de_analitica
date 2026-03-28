variable "project_name" {
    description = "The name of the project"
    type = string
    default = "pipeline"
  
}

variable "environment" {
    description = "The environment to deploy to"
    type = string
    default = "dev"
  
}

variable "kms_key_id" {
    description = "The id of the KMS key to use for encryption"
    type = string

}

variable "owner" {
    description = "The name of the Owner"
    type = string  
}
