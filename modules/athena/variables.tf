variable "s3_bucket" {
    description = "Athena s3 bucket"
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

variable "tenant" {
    description = "Nombre del Cliente"
    type = string
    default = ""
  
}

variable "prefix" {
    description = "the name of prefix for resources"
    type = string
}