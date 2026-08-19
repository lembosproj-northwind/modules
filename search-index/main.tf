# A managed search index with its analyzers and replica count.

locals {
  slug   = replace(var.name, "/", "-")
  domain = substr("${replace(var.environment, "/", "-")}-${local.slug}", 0, 28)

  sizing = {
    small  = { instance_type = "t3.small.search", instance_count = 1, volume_gb = 10, zone_awareness = false }
    medium = { instance_type = "m6g.large.search", instance_count = 2, volume_gb = 100, zone_awareness = true }
    large  = { instance_type = "m6g.2xlarge.search", instance_count = 4, volume_gb = 500, zone_awareness = true }
  }
  size = local.sizing[var.size_class]

  secret_ref = "${var.environment}/${var.name}"

  tags = merge(var.tags, {
    "lembos.dev/resource"    = var.name
    "lembos.dev/environment" = var.environment
    "lembos.dev/stamp"       = var.stamp
  })
}

resource "aws_opensearch_domain" "this" {
  domain_name    = local.domain
  engine_version = "OpenSearch_${var.engine_version}"

  cluster_config {
    instance_type          = local.size.instance_type
    instance_count         = local.size.instance_count
    zone_awareness_enabled = local.size.zone_awareness

    dynamic "zone_awareness_config" {
      for_each = local.size.zone_awareness ? [1] : []

      content {
        availability_zone_count = 2
      }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = local.size.volume_gb
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = local.tags
}

resource "aws_secretsmanager_secret" "connection" {
  name = local.secret_ref
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "connection" {
  secret_id     = aws_secretsmanager_secret.connection.id
  secret_string = jsonencode({ url = "https://${aws_opensearch_domain.this.endpoint}" })
}
