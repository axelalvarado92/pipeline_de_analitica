resource "aws_kinesis_stream" "kinesis_stream" {
    name = "${var.project_name}-events-stream-${var.environment}"
    shard_count = 1
    retention_period = 48
    encryption_type = "KMS"
    kms_key_id = var.kms_key_id
    shard_level_metrics = [
       "ALL"
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"   ### Elegí provisioned para tener control sobre costos y capacidad
  }

  tags = local.common_tags
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
  }
}
