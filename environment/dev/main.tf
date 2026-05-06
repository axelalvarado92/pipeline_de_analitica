locals {
  prefix = "${var.project_name}-${var.tenant}-${var.environment}"
}
#####################################################################
#                          Recursos
#####################################################################
  
resource "aws_cloudwatch_event_rule" "event_rule_crawler" {
  name        = "${local.prefix}-trigger-crawler"
  description = "Dispara el crawler cuando se suben objetos a processed/events"

  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail-type = ["Object Created"]

    detail = {
      bucket = {
        name = ["${local.prefix}-data-47148"]
      }

      object = {
        key = [
          {
            prefix = "processed/events/"
          }
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "event_target_crawler" {
  target_id = "${local.prefix}-trigger-crawler-target"
  rule = aws_cloudwatch_event_rule.event_rule_crawler.name
  arn  = module.trigger_glue.lambda_arn

  depends_on = [
    aws_cloudwatch_event_rule.event_rule_crawler,
    module.trigger_glue
  ]
}

resource "aws_lambda_permission" "event_rule_permission" {
  statement_id  = "${local.prefix}-event-rule-permission"
  action        = "lambda:InvokeFunction"
  function_name = module.trigger_glue.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule_crawler.arn

  depends_on = [
    aws_cloudwatch_event_rule.event_rule_crawler,
    module.trigger_glue
  ]

}

resource "aws_dynamodb_table" "pipeline_dedup" {
  name         = "${local.prefix}-dedup"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

resource "aws_s3_bucket_notification" "events_notification" {
  bucket = module.s3_data.bucket_name

  lambda_function {
  id                  = "raw-to-processed"
  lambda_function_arn = module.s3_event_processor.lambda_arn
  events              = ["s3:ObjectCreated:*"]
  filter_prefix       = "raw/events/"
}

lambda_function {
  id                  = "processed-to-glue"
  lambda_function_arn = module.trigger_glue.lambda_arn
  events              = ["s3:ObjectCreated:*"]
  filter_prefix       = "processed/events/"
}

 depends_on = [
  module.s3_event_processor,
  module.trigger_glue,
  module.s3_event_processor.lambda_permission,
  module.trigger_glue.lambda_permission
]
  
}

##############################################################
#                        Lambdas
##############################################################

data "archive_file" "s3_event_processor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/s3_event_processor"
  output_path = "${path.module}/../../build/s3_event_processor.zip"
}

data "archive_file" "trigger_glue_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/trigger_glue"
  output_path = "${path.module}/../../build/trigger_glue.zip"
}

module "s3_event_processor" {
  source = "../../modules/lambda"
  prefix = local.prefix
  resource_name = "${local.prefix}-s3-event-processor"

  function_name = "${local.prefix}-s3-event-processor"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.s3_event_processor_zip.output_path
  source_code_hash = data.archive_file.s3_event_processor_zip.output_base64sha256

  memory_size = 128

  enable_s3_trigger = true
  dynamodb_table_arn = aws_dynamodb_table.pipeline_dedup.arn

  bucket_arn  = module.s3_data.bucket_arn

  environment_variables = {
    BUCKET_NAME = module.s3_data.bucket_name
    TENANT      = var.tenant
    ENV         = var.environment
    PROJECT     = var.project_name
    DYNAMODB_TABLE = aws_dynamodb_table.pipeline_dedup.name
    PIPELINE_MODE = "batch"
    COOLDOWN_SECONDS = "300"
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

  enable_s3_trigger = true
 
  glue_crawler_arn = module.glue.glue_crawler_arn

  memory_size = 128

  environment_variables = {
    CRAWLER_NAME = module.glue.glue_crawler_name
    TENANT      = var.tenant
  }
}

##############################################################
#                        S3
##############################################################

module "s3_data" {
  source = "../../modules/s3"

  bucket_name = "${local.prefix}-data-47148"
  tags        = var.tags


  enable_versioning   = true
  enable_notifications = false

  lambda_arn = module.trigger_glue.lambda_arn

  filter_prefix = "processed/events/"

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

###################################################################

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
######################################################################
#                        QuickSight
######################################################################
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
