output "lambda_arn" {
  value = aws_lambda_function.generic_lambda.arn
}

output "lambda_name" {
  value = aws_lambda_function.generic_lambda.function_name
}