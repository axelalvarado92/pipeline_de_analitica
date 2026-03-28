output "kms_key_athena" {
    value = aws_kms_key.athena_key.arn
}
