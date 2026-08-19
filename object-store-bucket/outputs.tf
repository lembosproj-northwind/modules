output "resource_id" {
  value = aws_s3_bucket.this.id
}

output "endpoint" {
  description = "The bucket's regional domain name."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "port" {
  description = "Object storage has no port. Null rather than 443, so a caller can tell the difference."
  value       = null
}

output "secret_ref" {
  value = aws_secretsmanager_secret.connection.name
}

output "bucket" {
  value = aws_s3_bucket.this.bucket
}
