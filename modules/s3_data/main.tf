resource "aws_s3_bucket" "data_bucket" {
    bucket = var.bucket_name

    tags = var.tags
}

resource "aws_s3_bucket_versioning" "versioning_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.trigger_glue.arn
    events              = ["s3:ObjectCreated:*"]

    filter_prefix = "processed/events/"
  }
}