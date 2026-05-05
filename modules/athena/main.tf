resource "aws_athena_workgroup" "athena_workgroup" {
  name = "${var.prefix}-athena-wg"

  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.s3_bucket}/${var.prefix}/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = {
    Tenant      = var.tenant
  }
}

