resource "aws_lambda_event_source_mapping" "lambda_trigger" {
    event_source_arn = module.kinesis.kinesis_arns
    function_name = module.kinesis_event_processor.lambda_name
    starting_position = "LATEST"
    batch_size = 1           ### Dejo uno para testing
  
}

data "archive_file" "kinesis_event_processor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/kinesis_event_processor"
  output_path = "../../build/kinesis_event_processor.zip"
}

data "archive_file" "trigger_glue_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/trigger_glue"
  output_path = "../../build/trigger_glue.zip"
}

module "kinesis_event_processor" {
  source = "../../modules/lambda"

  function_name = "kinesis-event-processor"
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
  }
}

module "trigger_glue" {
  source = "../../modules/lambda"

  function_name = "trigger-glue"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.trigger_glue_zip.output_path
  source_code_hash = data.archive_file.trigger_glue_zip.output_base64sha256

  memory_size = 128

  kms_key_arn = module.kms.kms_key_arn

  glue_crawler_name = module.glue.glue_crawler_name

  environment_variables = {
    CRAWLER_NAME = module.glue.glue_crawler_name
  }
}


module "kinesis" {
    source = "../../modules/kinesis"
    owner = "empresa"
    project_name = var.project_name
    environment  = var.environment
    kms_key_id = module.kms.kms_key_arn
}

module "kms" {
    source = "../../modules/kms"
    environment = "dev"
    source_arn = "*"
}

module "kms_athena" {
    source = "../../modules/kms_athena"
    environment = "dev"
  
}

module "s3_data" {
    source = "../../modules/s3_data"
    bucket_name = "${var.project_name}-data-${var.environment}-47148"
    lambda_trigger_arn = module.trigger_glue.lambda_arn
    tags = {
        owner = "empresa"
        environment = var.environment
    }
  
}

module "s3_athena" {
    source = "../../modules/s3_athena"
    bucket_name = "${var.project_name}-athena-results-${var.environment}-47148"
    tags = {
        owner = "empresa"
        environment = var.environment
    }
    kms_key_arn = module.kinesis.kinesis_arns
}

module "athena" {
    source = "../../modules/athena"
    kms_key_athena = module.kms_athena.kms_key_athena
    s3_bucket = module.s3_athena.bucket_id
  
}

module "glue" {
    source = "../../modules/glue"
    bucket_arn = module.s3_data.bucket_arn
    bucket_name = module.s3_data.bucket_name
   
    s3_target = "s3://${module.s3_data.bucket_id}processed/events/"
    
}