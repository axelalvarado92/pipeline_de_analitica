resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.prefix}"
  target_key_id = aws_kms_key.primary_key.id
}

resource "aws_kms_key" "primary_key" {
  description             = "KMS key for event streaming pipeline encryption"
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.kms_policy_doc.json
  enable_key_rotation = true
  
  tags = var.tags
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms_policy_doc" {
  statement {
   sid    = "EnableRootAccess"
   effect = "Allow"

  principals {
    type        = "AWS"
    identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  }

  actions = ["kms:*"]
  resources = ["*"]
}

  statement {
    sid = "EnableKinesis"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["kinesis.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:ReEncrypt*"
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = var.sources_arns
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
