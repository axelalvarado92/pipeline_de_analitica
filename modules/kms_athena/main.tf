data "aws_caller_identity" "current" {}

resource "aws_kms_key" "athena_key" {
  description         = "KMS key for Athena results"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "EnableRoot"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Sid = "AllowAthena"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}