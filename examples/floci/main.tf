# A root configuration that points the AWS provider at Floci instead of a real account.
#
# This lives here rather than inside each module on purpose: a module that configures its own
# provider can only ever run in one place. Keeping the endpoints in the root is what lets the same
# postgres-cluster module serve a laptop and a production account.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

variable "floci_endpoint" {
  description = "Where Floci is listening. The Aspire app host injects this."
  type        = string
  default     = "http://localhost:4566"
}

provider "aws" {
  region = "eu-west-1"

  # Floci accepts anything; these exist because the provider requires them.
  access_key = "floci"
  secret_key = "floci"

  # Every check that would call out to a real account, turned off.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3             = var.floci_endpoint
    rds            = var.floci_endpoint
    elasticache    = var.floci_endpoint
    lambda         = var.floci_endpoint
    iam            = var.floci_endpoint
    sts            = var.floci_endpoint
    secretsmanager = var.floci_endpoint
    cloudfront     = var.floci_endpoint
    es             = var.floci_endpoint
    kafka          = var.floci_endpoint
  }
}

# One resource of each shape, as the smoke test the provisioning workflow will later drive.

module "orders_db" {
  source = "../../postgres-cluster"

  name        = "ordering/orders-db"
  environment = "northwind/dev"
  stamp       = "default"
  size_class  = "small"
}

module "session_cache" {
  source = "../../redis-cache"

  name        = "checkout/session-cache"
  environment = "northwind/dev"
  stamp       = "default"
  size_class  = "small"
}

module "lakehouse_bucket" {
  source = "../../object-store-bucket"

  name        = "data/lakehouse-bucket"
  environment = "northwind/dev"
  stamp       = "default"
  size_class  = "large"
}

output "orders_db_secret_ref" {
  description = "What the chart's resourceBindings.ordersDb.secretRef is set from."
  value       = module.orders_db.secret_ref
}
