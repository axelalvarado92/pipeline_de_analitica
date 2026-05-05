locals {
  prefix = "${var.project_name}-${var.tenant}-${var.environment}"
}

resource "aws_lambda_event_source_mapping" "lambda_trigger" {
    event_source_arn = module.kinesis.kinesis_arns
    function_name = module.kinesis_event_processor.lambda_name
    starting_position = "LATEST"
    batch_size = 1           ### Dejo uno para testing

    depends_on = [
      module.kinesis,
      module.kinesis_event_processor
  ]
}
  


data "archive_file" "kinesis_event_processor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/kinesis_event_processor"
  output_path = "${path.module}/../../build/kinesis_event_processor.zip"
}

data "archive_file" "trigger_glue_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/trigger_glue"
  output_path = "${path.module}/../../build/trigger_glue.zip"
}

module "kinesis_event_processor" {
  source = "../../modules/lambda"
  prefix = local.prefix
  resource_name = "${local.prefix}-kinesis-event-processor"

  function_name = "${local.prefix}-kinesis-event-processor"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.kinesis_event_processor_zip.output_path
  source_code_hash = data.archive_file.kinesis_event_processor_zip.output_base64sha256

  memory_size = 128

  kinesis_arns = [module.kinesis.kinesis_arns]

  bucket_arn  = module.s3_data.bucket_arn

  environment_variables = {
    BUCKET_NAME = module.s3_data.bucket_name
    TENANT      = var.tenant
    ENV         = var.environment
    PROJECT     = var.project_name
  }
}

module "trigger_glue" {
  source = "../../modules/lambda"
  prefix = local.prefix
  resource_name = "${local.prefix}-trigger-glue"

  function_name = "${local.prefix}-trigger-glue"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.trigger_glue_zip.output_path
  source_code_hash = data.archive_file.trigger_glue_zip.output_base64sha256

  memory_size = 128

 glue_crawler_arn = module.glue.glue_crawler_arn

  environment_variables = {
    CRAWLER_NAME = module.glue.glue_crawler_arn
    TENANT      = var.tenant
  }
}


module "kinesis" {
    source = "../../modules/kinesis"
    prefix = local.prefix
    owner = var.tenant
    project_name = var.project_name
    environment  = var.environment
}

module "s3_data" {
  source = "../../modules/s3"

  bucket_name = "${local.prefix}-data-47148"
  tags        = var.tags


  enable_versioning   = true
  enable_notifications = false

  lambda_arn = module.trigger_glue.lambda_arn

  filter_prefix = "processed/events/"

}

resource "aws_s3_bucket_notification" "events_notification" {
  bucket = module.s3_data.bucket_name

  lambda_function {
    lambda_function_arn = module.trigger_glue.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "processed/events/"
  }

  depends_on = [
    module.trigger_glue,
    module.trigger_glue.lambda_permission
  ]
}

module "s3_logs" {
  source = "../../modules/s3"

  bucket_name = "pipeline-${var.tenant}-dev-logs-47148"
  tags        = var.tags

}

module "s3_athena" {
  source = "../../modules/s3_athena"
  
  prefix       = local.prefix
  tenant       = var.tenant
}

module "athena" {
    source = "../../modules/athena"
    prefix = local.prefix
    s3_bucket = module.s3_athena.bucket_id
  
}

module "glue" {
    source = "../../modules/glue"
    prefix = local.prefix
    bucket_arn = module.s3_data.bucket_arn
    bucket_name = module.s3_data.bucket_name
   
    s3_target = "s3://${module.s3_data.bucket_id}/processed/events/"
    
}

data "aws_caller_identity" "current" {}

module "qs_datasource" {
  source = "../../modules/qs_datasource"

  prefix         = local.prefix
  aws_account_id = data.aws_caller_identity.current.account_id
  work_group     = module.athena.workgroup_name

  quicksight_principals = [var.qs_user_arn]

 depends_on = [
    module.s3_athena,     # ← MÓDULO COMPLETO
    module.athena,        # ← MÓDULO COMPLETO  
  ]
}

module "events_dataset" {
  source = "../../modules/qs_dataset"

  prefix              = local.prefix
  aws_account_id      = data.aws_caller_identity.current.account_id
  glue_database       = module.glue.glue_database_name

  dataset_name = "events"
  table_name   = "events"

  data_source_arn = module.qs_datasource.arn

  dataset_columns = [
    { name = "user_id", type = "STRING" },
    { name = "event_type", type = "STRING" }
  ]

  quicksight_principals = [var.qs_user_arn]
}

module "sales_dataset" {
  source = "../../modules/qs_dataset"

  prefix              = local.prefix
  aws_account_id      = data.aws_caller_identity.current.account_id
  glue_database       = module.glue.glue_database_name

  dataset_name = "sales"
  table_name   = "sales"

  data_source_arn = module.qs_datasource.arn

  dataset_columns = [
    { name = "destination", type = "STRING" },
    { name = "amount", type = "DECIMAL" },
    { name = "seller", type = "STRING" }
  ]

  quicksight_principals = [var.qs_user_arn]
}
