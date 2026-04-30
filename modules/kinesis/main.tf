locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_kinesis_stream" "kinesis_stream" {
    name = "${var.prefix}-events-stream"
    retention_period = 24
    encryption_type = "KMS"
    kms_key_id = var.kms_key_id
    shard_level_metrics = [
       "ALL"
  ]

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = local.common_tags
}

