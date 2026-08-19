# A Kubernetes cluster for one environment stamp, and the execution target it becomes.
#
# The only blueprint here that produces somewhere to run rather than something that runs. Its version
# carries an ExecutionTargetTemplate, so applying it registers a target in the catalog and placement can
# route to it — which is what makes the cluster something Lembos created rather than something it was
# handed.

locals {
  slug    = replace(var.name, "/", "-")
  cluster = substr("${local.slug}-${var.stamp}", 0, 38)

  # Sized by stage, not by a size class. What a cluster needs is a property of what it hosts, and a stage
  # already says that — a developer never chooses "large" for an environment they do not own.
  sizing = {
    Development = { instance_type = "t3.medium", desired = 2, min = 1, max = 4 }
    Test        = { instance_type = "t3.medium", desired = 2, min = 1, max = 4 }
    Staging     = { instance_type = "m6i.large", desired = 3, min = 2, max = 8 }
    Production  = { instance_type = "m6i.xlarge", desired = 6, min = 3, max = 24 }
  }
  size = local.sizing[var.stage]

  # Production keeps its control-plane logs; below it they are noise nobody reads and storage somebody pays
  # for.
  log_types = var.stage == "Production" ? ["api", "audit", "authenticator"] : []

  secret_ref = "${var.name}/${var.stamp}/kubeconfig"

  tags = merge(var.tags, {
    "lembos.dev/environment" = var.name
    "lembos.dev/stamp"       = var.stamp
    "lembos.dev/stage"       = var.stage
  })
}

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.cluster}-cluster"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${local.cluster}-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = local.tags
}

resource "aws_vpc" "this" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.tags, { Name = local.cluster })
}

# Two subnets in different zones, because a control plane will not come up in one and a stamp that cannot
# survive a zone is not a production stamp.
resource "aws_subnet" "this" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 4, count.index)
  availability_zone = "${var.region}${count.index == 0 ? "a" : "b"}"
  tags              = merge(local.tags, { Name = "${local.cluster}-${count.index}" })
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  enabled_cluster_log_types = local.log_types

  vpc_config {
    subnet_ids = aws_subnet.this[*].id
    # Reachable from outside only below production; production is entered through the platform's own path.
    endpoint_public_access  = var.stage != "Production"
    endpoint_private_access = true
  }

  tags = local.tags
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster}-workers"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.this[*].id
  instance_types  = [local.size.instance_type]

  scaling_config {
    desired_size = local.size.desired
    min_size     = local.size.min
    max_size     = local.size.max
  }

  tags = local.tags
}

# How something reaches the cluster, kept where credentials are kept. The path is what leaves this module;
# the certificate and the token do not.
resource "aws_secretsmanager_secret" "kubeconfig" {
  name = local.secret_ref
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "kubeconfig" {
  secret_id = aws_secretsmanager_secret.kubeconfig.id

  secret_string = jsonencode({
    url                   = aws_eks_cluster.this.endpoint
    cluster               = aws_eks_cluster.this.name
    certificate_authority = try(aws_eks_cluster.this.certificate_authority[0].data, null)
  })
}
