# Providers are required but not configured: the root module owns that. This module needs two — the
# Kafka protocol to create the topic, and AWS to record where its coordinates are kept.
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60"
    }
    kafka = {
      source  = "Mongey/kafka"
      version = ">= 0.7"
    }
  }
}
