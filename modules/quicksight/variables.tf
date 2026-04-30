variable "project_name" {
    description = "The name of the project"
    type = string
    default = "pipeline"
  
}

variable "prefix" {
    description = "The prefix for resource names"
    type = string
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


variable "aws_account_id" {
    description = "The aws account id"
    type = string
  
}

variable "dataset_columns" {
    description = "The columns of the glue database"
    type = list(object({
      name = string
      type = string
    }))
  
}

variable "work_group" {
    description = "The name of the athena workgroup"
    type = string
  
}

variable "dataset_name" {
    description = "The name of the dataset"
    type = string
  
}

variable "import_mode" {
    description = "The import mode for the quicksight dataset (SPICE or DIRECT_QUERY)"
    type = string
    default = "SPICE"
}

variable "table_name" {
    description = "The name of the table in the glue database"
    type = string
  
}

variable "quicksight_principals" {
  type = list(string)
}
