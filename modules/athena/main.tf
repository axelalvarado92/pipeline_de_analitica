resource "aws_athena_workgroup" "athena_workgroup" {
  name = "${var.prefix}-athena-wg"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.s3_bucket}/${var.prefix}/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = var.kms_key_athena
      }
    }
  }

  tags = {
    Tenant      = var.tenant
  }
}