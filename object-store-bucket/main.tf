# An object-storage bucket with lifecycle rules and encryption at rest.

locals {
  slug   = replace(var.name, "/", "-")
  bucket = "${replace(var.environment, "/", "-")}-${local.slug}"

  sizing = {
    small  = { expire_days = 30, noncurrent_days = 7, versioning = false }
    medium = { expire_days = 180, noncurrent_days = 30, versioning = true }
    large  = { expire_days = 0, noncurrent_days = 90, versioning = true }
  }
  size = local.sizing[var.size_class]

  secret_ref = "${var.environment}/${var.name}"

  tags = merge(var.tags, {
    "lembos.dev/resource"    = var.name
    "lembos.dev/environment" = var.environment
    "lembos.dev/stamp"       = var.stamp
  })
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = local.size.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket     = aws_s3_bucket.this.id
  depends_on = [aws_s3_bucket_versioning.this]

  # `large` keeps current objects forever — a lake bucket that expired its own contents after six
  # months would be a data loss the size class quietly caused.
  dynamic "rule" {
    for_each = local.size.expire_days > 0 ? [1] : []

    content {
      id     = "expire-current"
      status = "Enabled"
      filter {}

      expiration {
        days = local.size.expire_days
      }
    }
  }

  rule {
    id     = "expire-noncurrent"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = local.size.noncurrent_days
    }
  }
}

resource "aws_secretsmanager_secret" "connection" {
  name = local.secret_ref
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "connection" {
  secret_id     = aws_secretsmanager_secret.connection.id
  secret_string = jsonencode({ url = "s3://${aws_s3_bucket.this.bucket}" })
}
