resource "aws_quicksight_data_source" "qs_athena_datasource" {
  data_source_id = "${var.prefix}-datasource-qs-id"
  name           = "${var.prefix}-datasource-qs"
  aws_account_id = var.aws_account_id
  type = "ATHENA"

  parameters {
    athena {
        work_group = var.work_group
    }
  }

  dynamic "permission" {
  for_each = [
    for p in var.quicksight_principals : p
    if p != null && p != ""
  ]

  content {
    principal = permission.value

    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource",
      "quicksight:UpdateDataSourcePermissions"
    ]
  }
}
}


resource "aws_quicksight_data_set" "qs_data_set" {
  aws_account_id = var.aws_account_id

  data_set_id = "${var.prefix}-${var.dataset_name}-dataset-id"
  name        = "${var.prefix}-${var.dataset_name}-dataset"
  import_mode = var.import_mode

  physical_table_map {
    physical_table_map_id = var.table_name

    relational_table {
      data_source_arn = aws_quicksight_data_source.qs_athena_datasource.arn
      name            = var.table_name
      schema          = var.glue_database

      dynamic "input_columns" {
        for_each = var.dataset_columns

        content {
          name = input_columns.value.name
          type = input_columns.value.type
        }
      }
    }
  }

  dynamic "permissions" {
  for_each = [
    for p in var.quicksight_principals : p
    if p != null && p != ""
  ]

  content {
    principal = permissions.value

    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:CreateIngestion",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet"
    ]
  }
 }
}