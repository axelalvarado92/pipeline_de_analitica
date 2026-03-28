resource "aws_lambda_event_source_mapping" "lambda_trigger" {
    event_source_arn = module.kinesis.kinesis_arns
    function_name = module.kinesis_event_processor.lambda_function_name
    starting_position = "LATEST"
    batch_size = 1           ### Dejo uno para testing
  
}

data "archive_file" "kinesis_event_processor_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/kinesis_event_processor"
  output_path = "../../build/kinesis_event_processor.zip"
}

module "kinesis_event_processor" {
    source = "../../modules/lambda"
    function_name = "kinesis-event-processor"
    handler = "lambda_function.lambda_handler"
    filename         = data.archive_file.kinesis_event_processor_zip.output_path
    source_code_hash = data.archive_file.kinesis_event_processor_zip.output_base64sha256
    memory_size = 128

    kinesis_arns = [module.kinesis.kinesis_arns]
    kms_key_arn = module.kms.kms_key_arn

    bucket_arn = module.s3_data.bucket_arn

    environment_variables = {
       BUCKET_NAME = module.s3_data.bucket_id
    }
}



module "kinesis" {
    source = "../../modules/kinesis"
    owner = "empresa"
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
    s3_target = "s3://${module.s3_data.bucket_id}/events/"
   
}