output "kms_key_arn" {
    value = aws_kms_key.primary_key.arn
}

output "kms_key_id" {
    value = aws_kms_key.primary_key.id
}

output "kms_alias" {
    value = aws_kms_alias.kms_alias.name
}