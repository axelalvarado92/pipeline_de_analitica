output "lambda_arn" {
  value = aws_lambda_function.generic_lambda.arn
}

output "lambda_name" {
  value = aws_lambda_function.generic_lambda.function_name
}

output "lambda_permission_id" {
  value = aws_lambda_permission.allow_s3.id
}