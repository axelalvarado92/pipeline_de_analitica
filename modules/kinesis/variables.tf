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

variable "owner" {
    description = "The name of the Owner"
    type = string  
}

variable "prefix" {
    description = "the name of prefix for resources"
    type = string
}