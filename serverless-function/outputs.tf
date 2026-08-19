output "resource_id" {
  value = aws_lambda_function.this.function_name
}

output "endpoint" {
  description = "The function ARN. A function has no host, so this is what a caller invokes."
  value       = aws_lambda_function.this.arn
}

output "port" {
  value = null
}

output "version" {
  description = "The published version, which is what a rollback would target."
  value       = aws_lambda_function.this.version
}
