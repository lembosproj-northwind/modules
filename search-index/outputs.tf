output "resource_id" {
  value = aws_opensearch_domain.this.domain_name
}

output "endpoint" {
  value = aws_opensearch_domain.this.endpoint
}

output "port" {
  value = 443
}

output "secret_ref" {
  value = aws_secretsmanager_secret.connection.name
}
