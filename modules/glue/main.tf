resource "aws_glue_catalog_database" "pipeline_events_db" {
  name = "${var.project_name}-${var.environment}-events-db"
}

resource "aws_glue_crawler" "crawler_s3" {
  database_name = aws_glue_catalog_database.pipeline_events_db.name
  name          = "${var.project_name}-${var.environment}-crawler"
  role          = aws_iam_role.glue_role.arn
  schedule      = "cron(0 * * * ? *)"

  configuration = jsonencode({
  Version = 1.0,
  CrawlerOutput = {
    Tables = {
      AddOrUpdateBehavior = "MergeNewColumns" ### Si encuentra una columna nueva, la agrega SIN romper lo anterior.
    }                                         ### evolución suave del schema.
  }
})

  s3_target {
    path = "s3://${var.bucket_name}/${var.data_prefix}"  ### utilizo data data_prefix para hacer el modulo reutilizable
  }

  schema_change_policy {
  update_behavior = "UPDATE_IN_DATABASE"    ### Si aparece una columna nueva, la agrega automáticamente.
  delete_behavior = "LOG"                   ### Si algo desaparece, solo anotá, no borra nada.
  }
}

resource "aws_iam_role" "glue_role" {
  name = "${var.project_name}-${var.environment}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

data "aws_iam_policy_document" "glue_policy_doc" {
    statement {
        effect = "Allow"
        actions = [
            "s3:GetBucketLocation",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads"
        ]
        resources = [
             "${var.bucket_arn}",
             "${var.bucket_arn}/*"
        ]
    }

    statement {
        effect = "Allow"
        actions = [
            "s3:GetObject"
        ]
        resources = [
             "${var.bucket_arn}",
             "${var.bucket_arn}/*"
        ]
    }
}

resource "aws_iam_policy" "glue_policy" {
    name        = "${var.project_name}-${var.environment}-glue-policy"
    policy      = data.aws_iam_policy_document.glue_policy_doc.json
  
}

resource "aws_iam_role_policy_attachment" "glue_attachment" {
    role       = aws_iam_role.glue_role.name
    policy_arn = aws_iam_policy.glue_policy.arn
  
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

