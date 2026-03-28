resource "aws_s3_bucket" "athena_bucket" {
    bucket = var.bucket_name

    tags = var.tags
    
}

resource "aws_s3_bucket_versioning" "athena_bucket_versioning" {
  bucket = aws_s3_bucket.athena_bucket.id
  versioning_configuration {
    status = "Enabled"
  }

  depends_on = [aws_s3_bucket.athena_bucket]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_athena_encryption" {
  bucket = aws_s3_bucket.athena_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "athena_block" {
  bucket = aws_s3_bucket.athena_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}