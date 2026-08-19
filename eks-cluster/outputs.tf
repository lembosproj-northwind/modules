# The first four are the resource-module contract, so anything that reads a provisioning output reads this
# one the same way. The rest are what an ExecutionTarget is registered from.

output "resource_id" {
  value = aws_eks_cluster.this.name
}

output "endpoint" {
  description = "The API server. What a deployment connects to."
  value       = aws_eks_cluster.this.endpoint
}

output "port" {
  description = "Carried in the endpoint, so null rather than a second copy that could disagree with it."
  value       = null
}

output "secret_ref" {
  description = "Where the kubeconfig is kept. Never the kubeconfig itself."
  value       = aws_secretsmanager_secret.kubeconfig.name
}

# ── What the generated ExecutionTarget is registered with ──

output "target_provider" {
  value = "aws"
}

output "target_region" {
  value = var.region
}

output "target_type" {
  value = "kubernetes"
}

output "target_capabilities" {
  description = <<-EOT
    Echoed back rather than re-derived. The catalog records what this target advertises, and the only
    honest source for that is the value the run was given — a second opinion computed here could disagree
    with the cluster that was actually built.
  EOT
  value       = var.capabilities
}

output "oidc_issuer" {
  description = "For binding workload identities to this cluster later."
  value       = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, null)
}
