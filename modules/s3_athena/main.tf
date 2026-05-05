data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "athena_bucket" {
  bucket        = "${var.prefix}-athena-results"
  force_destroy = true
}

# Bucket policy ANTES que cualquier otra cosa
resource "aws_s3_bucket_policy" "athena_access" {
  bucket = aws_s3_bucket.athena_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAthenaService"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.athena_bucket.arn,
          "${aws_s3_bucket.athena_bucket.arn}/*"
        ]
      },
      {
        Sid    = "AllowQuickSightService"
        Effect = "Allow"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.athena_bucket.arn,
          "${aws_s3_bucket.athena_bucket.arn}/*"
        ]
      },
      {
        Sid    = "AllowRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject*",
          "s3:PutObject*",
          "s3:DeleteObject*"
        ]
        Resource = [
          aws_s3_bucket.athena_bucket.arn,
          "${aws_s3_bucket.athena_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.athena_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket_policy.athena_access]
}


resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.athena_bucket.id 

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [aws_s3_bucket.athena_bucket]
}

# En s3_athena/main.tf - AGREGAR al final:
resource "aws_s3_bucket_policy" "quicksight_access" {
  bucket = aws_s3_bucket.athena_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowQuickSightAccess"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::426718765503:role/service-role/aws-quicksight-service-role-v0"
        }

        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]

        Resource = [
          aws_s3_bucket.athena_bucket.arn,
          "${aws_s3_bucket.athena_bucket.arn}/*"
        ]
      }
    ]
  })
}

