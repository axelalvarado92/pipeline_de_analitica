variable "region" {
    default = "us-east-1"
    type = string
}

variable "project_name" {
    description = "Nombre del proyecto"
    default = "pipeline"
    type = string
}

variable "environment" {
    description = "Nombre del ambiente"
    default = "dev"
    type = string
  
}

variable "tenant" {
    description = "Nombre del Cliente"
    type = string
  
}

variable "qs_user_arn" {
    description = "Arn de quicksight"
    type = string
    default = ""

}

variable "tags" {
  type = map(string)
  default = {
    Project = "pipeline"
    Environment = "dev"
    Tenant = "tenant"

  }
}
