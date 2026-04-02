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

variable "glue_database" {
    description = "The name of the athena database"
    type = string
  
}

variable "quicksight_user_arn" {
    description = "The arn of the quicksight user"
    type = string
  
}

variable "aws_account_id" {
    description = "The aws account id"
    type = string
  
}