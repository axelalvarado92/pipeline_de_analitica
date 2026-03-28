output "bucket_arn" {
    value = aws_s3_bucket.data_bucket.arn
}

output "bucket_id" {
    value = aws_s3_bucket.data_bucket.id
}
