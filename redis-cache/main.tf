# A managed Redis instance, sized from a t-shirt parameter.

locals {
  slug = replace(var.name, "/", "-")

  sizing = {
    small  = { node_type = "cache.t4g.micro", replicas = 0, failover = false }
    medium = { node_type = "cache.t4g.medium", replicas = 1, failover = true }
    large  = { node_type = "cache.r7g.large", replicas = 2, failover = true }
  }
  size = local.sizing[var.size_class]

  secret_ref = "${var.environment}/${var.name}"

  tags = merge(var.tags, {
    "lembos.dev/resource"    = var.name
    "lembos.dev/environment" = var.environment
    "lembos.dev/stamp"       = var.stamp
  })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = substr(local.slug, 0, 40)
  description          = "Lembos ${var.name} (${var.environment})"

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = local.size.node_type
  port           = 6379

  num_cache_clusters         = local.size.replicas + 1
  automatic_failover_enabled = local.size.failover
  multi_az_enabled           = local.size.failover

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  apply_immediately = true

  tags = local.tags
}

resource "aws_secretsmanager_secret" "connection" {
  name = local.secret_ref
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "connection" {
  secret_id = aws_secretsmanager_secret.connection.id
  secret_string = jsonencode({
    url = "rediss://${aws_elasticache_replication_group.this.primary_endpoint_address}:6379"
  })
}
