resource "aws_s3_bucket" "generic_bucket" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

# -------------------------
# Versioning (opcional)
# -------------------------
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.generic_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------------
# Encryptions
# -------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.generic_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

# -------------------------
# Block public access
# -------------------------
resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
  bucket = aws_s3_bucket.generic_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -------------------------
# Logging (opcional)
# -------------------------
resource "aws_s3_bucket_logging" "bucket_logging" {
  count = var.enable_logging ? 1 : 0

  bucket        = aws_s3_bucket.generic_bucket.id
  target_bucket = var.log_bucket
  target_prefix = var.log_prefix
}

# -------------------------
# Lifecycle (opcional)
# -------------------------
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.generic_bucket.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_noncurrent_days
    }
  }
}

# -------------------------
# Notifications (S3 → Lambda)
# -------------------------
resource "aws_s3_bucket_notification" "bucket_notifications" {
  count  = var.enable_notifications ? 1 : 0
  bucket = aws_s3_bucket.generic_bucket.id

  lambda_function {
    lambda_function_arn = var.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.filter_prefix
  }

 depends_on = [
  aws_s3_bucket_public_access_block.bucket_public_access,
  aws_s3_bucket_versioning.bucket_versioning
]
}


