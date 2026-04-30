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
  bucket = aws_s3_bucket.data_bucket.id
  lambda_function {
    lambda_function_arn = var.lambda_trigger_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.data_prefix}/events/"
    filter_suffix = ".json"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}