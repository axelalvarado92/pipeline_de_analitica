resource "aws_s3_bucket" "athena_bucket" {
    bucket = var.bucket_name

    tags = var.tags
    
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

resource "aws_s3_bucket_policy" "deny_unencrypted" {
  bucket = aws_s3_bucket.athena_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyUnEncryptedObjectUploads",
        Effect = "Deny",
        Principal = "*",
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.athena_bucket.arn}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_logging" "athena_logs" {
  bucket = aws_s3_bucket.athena_bucket.id

  target_bucket = var.log_bucket
  target_prefix = "${var.prefix}/logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_lifecycle" {
  bucket = aws_s3_bucket.athena_bucket.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}