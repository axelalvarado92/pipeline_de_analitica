resource "aws_kms_key" "athena_key" {
  description             = "KMS key for Athena results"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "athena_key_alias" {
  name          = "alias/${var.prefix}-athena-results-key"
  target_key_id = aws_kms_key.athena_key.arn
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms_athena_policy_doc" {
  statement {
    sid    = "EnableRoot"
    effect = "Allow"
    actions = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowAthena"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "kms:ReEncrypt*"
    ]
    resources = [aws_kms_key.athena_key.arn]

    condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }      
    }
  }

resource "aws_kms_key_policy" "kms_athena_policy" {
  key_id = aws_kms_key.athena_key.id
  policy = data.aws_iam_policy_document.kms_athena_policy_doc.json
}