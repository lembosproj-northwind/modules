# An event-driven function for work too small to justify a pod.

locals {
  slug = replace(var.name, "/", "-")
  fn   = substr("${replace(var.environment, "/", "-")}-${local.slug}", 0, 64)

  sizing = {
    small  = { memory_mb = 256, timeout = 30, concurrency = -1 }
    medium = { memory_mb = 1024, timeout = 120, concurrency = 50 }
    large  = { memory_mb = 3008, timeout = 900, concurrency = 200 }
  }
  size = local.sizing[var.size_class]

  tags = merge(var.tags, {
    "lembos.dev/component"   = var.name
    "lembos.dev/environment" = var.environment
    "lembos.dev/stamp"       = var.stamp
  })
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.fn}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.tags
}

# Reach is granted to exactly the secrets this component was bound to, rather than to the account's
# secrets as a class — the binding list is the authorisation, which is what makes it worth passing.
data "aws_iam_policy_document" "secrets" {
  count = length(var.resource_bindings) > 0 ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [for b in var.resource_bindings : "arn:aws:secretsmanager:*:*:secret:${b.secret_ref}*"]
  }
}

resource "aws_iam_role_policy" "secrets" {
  count = length(var.resource_bindings) > 0 ? 1 : 0

  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.secrets[0].json
}

resource "aws_lambda_function" "this" {
  function_name = local.fn
  role          = aws_iam_role.this.arn
  runtime       = var.runtime
  handler       = var.handler

  s3_bucket        = split("/", trimprefix(var.artifact_uri, "s3://"))[0]
  s3_key           = join("/", slice(split("/", trimprefix(var.artifact_uri, "s3://")), 1, length(split("/", trimprefix(var.artifact_uri, "s3://")))))
  source_code_hash = var.artifact_digest

  memory_size                    = local.size.memory_mb
  timeout                        = local.size.timeout
  reserved_concurrent_executions = local.size.concurrency

  environment {
    variables = merge(var.config, {
      LEMBOS_COMPONENT   = var.name
      LEMBOS_ENVIRONMENT = var.environment
      LEMBOS_STAMP       = var.stamp
      }, {
      for handle, binding in var.resource_bindings :
      "${upper(replace(handle, "-", "_"))}_SECRET_REF" => binding.secret_ref
    })
  }

  tags = local.tags
}
