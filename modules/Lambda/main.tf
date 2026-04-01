########################################
# Lambda Function
########################################
resource "aws_lambda_function" "generic_lambda" {
  filename         = var.filename
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  runtime          = "python3.12"
  timeout          = var.timeout
  memory_size      = var.memory_size
  source_code_hash = var.source_code_hash

  environment {
    variables = var.environment_variables
  }
}

########################################
# IAM Role
########################################
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

########################################
# IAM Policy Document (BASE)
########################################
data "aws_iam_policy_document" "lambda_policy_doc" {

  ########################################
  # Kinesis (solo si existe)
  ########################################
  dynamic "statement" {
    for_each = length(var.kinesis_arns) > 0 ? [1] : []

    content {
      sid = "KinesisAccess"

      actions = [
        "kinesis:GetRecords",
        "kinesis:GetShardIterator",
        "kinesis:ListShards",
        "kinesis:DescribeStream",
        "kinesis:DescribeStreamSummary",
        "kinesis:ListStreams"
      ]

      resources = var.kinesis_arns
    }
  }

  ########################################
  # KMS
  ########################################
  statement {
    sid = "KMSAccess"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [var.kms_key_arn]
  }

  ########################################
  # S3 Object Access (solo processed/)
  ########################################
  dynamic "statement" {
    for_each = var.bucket_arn != null ? [1] : []

    content {
      sid = "S3ObjectAccess"

      actions = [
        "s3:PutObject",
        "s3:GetObject"
      ]

      resources = [
        "${var.bucket_arn}/processed/*"
      ]

      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-server-side-encryption"   ### Obliga a que todo lo que escriba Lambda esté encriptado
        values   = ["aws:kms"]
      }
    }
  }

  ########################################
  # S3 ListBucket restringido
  ########################################
  dynamic "statement" {
  for_each = var.bucket_arn != null ? [1] : []  ### Si existe hace algo, si no existe no hace nada.
    
    content {
    sid = "S3ListBucket"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      var.bucket_arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"        ### Lambda puede acceder a S3,
      values   = ["processed/*"]    ### PERO solo a objetos que estén dentro de esta carpeta (prefijo)
    }
   }
  }

  ########################################
  # Glue (SIEMPRE disponible)
  ########################################
  statement {
    sid = "GlueStartCrawler"

    effect = "Allow"

    actions = [
      "glue:StartCrawler"
    ]

    resources = ["*"] 
  }
}

########################################
# IAM Policy (SIEMPRE creada)
########################################
resource "aws_iam_policy" "lambda_policy" {
  name   = "${var.function_name}-policy"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

########################################
# Attach Policy al Role (SIEMPRE)
########################################
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

########################################
# Logs (AWS Managed)
########################################
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

########################################
# Permiso S3 → Lambda
########################################
data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generic_lambda.function_name
  principal     = "s3.amazonaws.com"

  source_arn     = var.bucket_arn
  source_account = data.aws_caller_identity.current.account_id  ### da permisos de logs a la cuenta main
}