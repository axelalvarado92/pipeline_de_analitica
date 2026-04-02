resource "aws_quicksight_data_source" "qs_athena_datasource" {
  data_source_id = "${var.project_name}-${var.environment}-datasource-qs-id"
  name           = "${var.project_name}-${var.environment}-datasource-qs"
  aws_account_id = var.aws_account_id
  type = "ATHENA"

  parameters {
    athena {
        work_group = "primary"
    }
  }
  permission {
    principal = var.quicksight_user_arn

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



resource "aws_quicksight_data_set" "qs_data_set" {
  aws_account_id = var.aws_account_id

  data_set_id = "${var.project_name}-${var.environment}-dataset-qs-id"
  name        = "${var.project_name}-${var.environment}-dataset-qs"
  import_mode = "SPICE"

  physical_table_map {
    physical_table_map_id = "events-table"

    relational_table {
      data_source_arn = aws_quicksight_data_source.qs_athena_datasource.arn
      name            = "events"
      schema          = var.glue_database

      input_columns {
        name = "user_id"
        type = "STRING"
      }

      input_columns {
        name = "event_type"
        type = "STRING"
      }
    }
  }

  permissions {
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

    principal = var.quicksight_user_arn
  }
}