output "resource_id" {
  value = kafka_topic.this.name
}

output "endpoint" {
  description = "The bootstrap servers, not the topic — what a client connects to."
  value       = var.bootstrap_servers
}

output "port" {
  description = "Carried in bootstrap_servers, so null here rather than a second, disagreeable copy."
  value       = null
}

output "secret_ref" {
  value = aws_secretsmanager_secret.connection.name
}

output "schema_subject" {
  value = "${kafka_topic.this.name}-value"
}
