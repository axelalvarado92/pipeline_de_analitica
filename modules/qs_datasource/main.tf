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


