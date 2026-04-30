variable "environment" {
    description = "The environment to deploy to"
    type = string
}

variable "prefix" {
    description = "The prefix for resource names"
    type = string
}

variable "project_name" {
    description = "The project name to deploy"
    type = string
    default = "pipeline"
}