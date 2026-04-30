locals {
  prefix = "${var.project_name}-${var.tenant}-${var.environment}"
}

resource "aws_lambda_event_source_mapping" "lambda_trigger" {
    event_source_arn = module.kinesis.kinesis_arns
    function_name = module.kinesis_event_processor.lambda_name
    starting_position = "LATEST"
    batch_size = 1           ### Dejo uno para testing
  
}

data "archive_file" "kinesis_event_processor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/kinesis_event_processor"
  output_path = "${path.module}/build/kinesis_event_processor.zip"
}

data "archive_file" "trigger_glue_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/trigger_glue"
  output_path = "${path.module}/build/trigger_glue.zip"
}

module "kinesis_event_processor" {
  source = "../../modules/lambda"
  prefix = local.prefix

  function_name = "${local.prefix}-kinesis-event-processor"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.kinesis_event_processor_zip.output_path
  source_code_hash = data.archive_file.kinesis_event_processor_zip.output_base64sha256

  memory_size = 128

  kinesis_arns = [module.kinesis.kinesis_arns]
  kms_key_arn  = module.kms.kms_key_arn

  bucket_arn  = module.s3_data.bucket_arn

  environment_variables = {
    BUCKET_NAME = module.s3_data.bucket_name
    KMS_KEY_ID  = module.kms.kms_key_arn
    TENANT      = var.tenant
    ENV         = var.environment
    PROJECT     = var.project_name
  }
}

module "trigger_glue" {
  source = "../../modules/lambda"
  prefix = local.prefix

  function_name = "${local.prefix}-trigger-glue"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.trigger_glue_zip.output_path
  source_code_hash = data.archive_file.trigger_glue_zip.output_base64sha256

  memory_size = 128

  kms_key_arn = module.kms.kms_key_arn

  glue_crawler_name = module.glue.glue_crawler_name

  environment_variables = {
    CRAWLER_NAME = module.glue.glue_crawler_name
    TENANT      = var.tenant
  }
}


module "kinesis" {
    source = "../../modules/kinesis"
    prefix = local.prefix
    owner = var.tenant
    project_name = var.project_name
    environment  = var.environment
    kms_key_id = module.kms.kms_key_arn
}

module "kms" {
    source = "../../modules/kms"
    prefix = local.prefix
    environment = var.environment
    sources_arns = ["*"]
}

module "kms_athena" {
    source = "../../modules/kms_athena"
    prefix = local.prefix
    environment = var.environment
  
}

module "s3_data" {
  source = "../../modules/s3_data"

  bucket_name        = "${local.prefix}-data-47148"
  lambda_trigger_arn = module.trigger_glue.lambda_arn

  kms_key_arn = module.kms.kms_key_arn

  data_prefix = "processed"

  tags = {
    owner       = var.tenant
    environment = var.environment
  }
}

module "s3_logs" {
  source = "../../modules/s3_data" # o podés hacer uno más simple

  bucket_name = "${local.prefix}-logs-47148"

  kms_key_arn = module.kms.kms_key_arn
  data_prefix = "logs"

  lambda_trigger_arn = null

  tags = {
    owner       = var.tenant
    environment = var.environment
  }
}

module "s3_athena" {
  source = "../../modules/s3_athena"

  bucket_name = "${local.prefix}-athena-results-47148"

  kms_key_arn = module.kms_athena.kms_key_athena
  prefix = local.prefix

  log_bucket = module.s3_logs.bucket_id   # 👈 clave

  tags = {
    owner       = var.tenant
    environment = var.environment
  }
}

module "athena" {
    source = "../../modules/athena"
    prefix = local.prefix
    kms_key_athena = module.kms_athena.kms_key_athena
    s3_bucket = module.s3_athena.bucket_id
  
}

module "glue" {
    source = "../../modules/glue"
    prefix = local.prefix
    bucket_arn = module.s3_data.bucket_arn
    bucket_name = module.s3_data.bucket_name
    kms_key_arn = module.kms.kms_key_arn
   
    s3_target = "s3://${module.s3_data.bucket_id}/processed/events/"
    
}

data "aws_caller_identity" "current" {}

module "events_dataset" {
  source = "../../modules/quicksight"

  prefix              = local.prefix
  aws_account_id      = data.aws_caller_identity.current.account_id
  glue_database       = module.glue.glue_database_name
  quicksight_principals = [var.qs_user_arn]

  dataset_name = "events"
  table_name   = "events"

  dataset_columns = [
    { name = "user_id", type = "STRING" },
    { name = "event_type", type = "STRING" }
  ]

  work_group = module.athena.workgroup_name
}

module "sales_dataset" {
  source = "../../modules/quicksight"

  prefix              = local.prefix
  aws_account_id      = data.aws_caller_identity.current.account_id
  glue_database       = module.glue.glue_database_name
  quicksight_principals = [var.qs_user_arn]

  dataset_name = "sales"
  table_name   = "sales"

  dataset_columns = [
    { name = "destination", type = "STRING" },
    { name = "amount", type = "DECIMAL" },
    { name = "seller", type = "STRING" }
  ]

  work_group = module.athena.workgroup_name
}