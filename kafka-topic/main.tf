# One topic on the shared cluster, with its retention and schema-registry subject.
#
# The odd one out: this module does not create infrastructure, it creates a topic on a cluster that
# already exists. So it takes the broker as an input and speaks the Kafka protocol rather than the
# AWS API — which is why it needs a reachable broker where the other resource modules need only an
# endpoint override.

locals {
  topic = replace(trimprefix(var.name, "${split("/", var.name)[0]}/"), "/", ".")
  full  = "${replace(var.environment, "/", ".")}.${local.topic}"

  sizing = {
    small  = { partitions = 3, replication = 1, retention_hours = 24 }
    medium = { partitions = 12, replication = 3, retention_hours = 168 }
    large  = { partitions = 48, replication = 3, retention_hours = 720 }
  }
  size = local.sizing[var.size_class]

  secret_ref = "${var.environment}/${var.name}"
}

resource "kafka_topic" "this" {
  name               = local.full
  partitions         = local.size.partitions
  replication_factor = local.size.replication

  config = {
    "retention.ms"     = tostring(local.size.retention_hours * 3600 * 1000)
    "cleanup.policy"   = var.cleanup_policy
    "compression.type" = "producer"
  }
}

# The subject is named after the topic by convention, and the convention is enforced here rather than
# left to each producer — a topic whose schema subject does not match it is a schema nobody finds.
resource "aws_secretsmanager_secret" "connection" {
  name = local.secret_ref

  tags = merge(var.tags, {
    "lembos.dev/resource"    = var.name
    "lembos.dev/environment" = var.environment
    "lembos.dev/stamp"       = var.stamp
  })
}

resource "aws_secretsmanager_secret_version" "connection" {
  secret_id = aws_secretsmanager_secret.connection.id
  secret_string = jsonencode({
    url            = "kafka://${var.bootstrap_servers}/${kafka_topic.this.name}"
    topic          = kafka_topic.this.name
    schema_subject = "${kafka_topic.this.name}-value"
  })
}
