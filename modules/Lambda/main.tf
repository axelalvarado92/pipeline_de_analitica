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

data "aws_iam_policy_document" "lambda_policy_doc" {
    count = length(var.kinesis_arns) > 0 ? 1 : 0
    
    statement {
        sid = "KinesisReadAccess"
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
    statement {
     sid = "KMSDecryptAccess"

      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
    ]

        resources = [var.kms_key_arn]
    }

    statement {
      sid = "S3ObjectAccess"

      actions = [
        "s3:PutObject",
        "s3:GetObject"
      ]

      resources = [
    "${var.bucket_arn}/processed/*"
     ]

    condition {
      test = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"  ### Obliga a que todo lo que escriba Lambda esté encriptado
      values = ["aws:kms"]
    }
  }

    statement {
      sid = "S3ListBucket"

      actions = [
        "s3:ListBucket"
      ]

      resources = [
        var.bucket_arn
      ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"       ### Lambda puede acceder a S3, 
      values   = ["processed/*"]   ### PERO solo a objetos que estén dentro de esta carpeta (prefijo)
    }
  }
  statement {
    effect = "Allow"

     actions = [
    "glue:StartCrawler"
    ]

    resources = ["*"] 
 }
}

resource "aws_iam_policy" "kinesis_policy" {
    count = length(var.kinesis_arns) > 0 ? 1 : 0
    name        = "${var.function_name}-policy"
    description = "IAM policy for Lambda"
    policy      = data.aws_iam_policy_document.lambda_policy_doc[0].json
}

resource "aws_iam_role_policy_attachment" "kinesis_attachment" {
  count      = length(var.kinesis_arns) > 0 ? 1 : 0           
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.kinesis_policy[0].arn
}


resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_glue.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}

