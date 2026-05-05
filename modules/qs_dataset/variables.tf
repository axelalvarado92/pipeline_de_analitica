variable "prefix" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "dataset_name" {
  type = string
}

variable "table_name" {
  type = string
}

variable "glue_database" {
  type = string
}

variable "data_source_arn" {
  type = string
}

variable "dataset_columns" {
  type = list(object({
    name = string
    type = string
  }))
}

variable "quicksight_principals" {
  type = list(string)
}

variable "import_mode" {
  type    = string
  default = "SPICE"
}