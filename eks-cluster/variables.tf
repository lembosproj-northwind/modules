# An Environment blueprint, so this takes an environment and a stamp rather than a ResourceNeed. It is the
# substrate itself: what runs before anything can be deployed, and what everything else is then placed on.

variable "name" {
  description = "The Environment's qualified name, e.g. northwind/prod."
  type        = string
}

variable "stamp" {
  description = "The Stamp this cluster serves. One cluster per stamp is what makes a stamp a real boundary."
  type        = string
  default     = "default"
}

variable "stage" {
  description = "Development, Test, Staging or Production. What governance matches on, and what sizing follows."
  type        = string
  default     = "Development"

  validation {
    condition     = contains(["Development", "Test", "Staging", "Production"], var.stage)
    error_message = "stage must be Development, Test, Staging or Production."
  }
}

variable "region" {
  description = "Where it is provisioned. Becomes the region the generated ExecutionTarget advertises."
  type        = string
  default     = "eu-west-1"
}

variable "kubernetes_version" {
  description = "Pinned by the blueprint rather than chosen per environment, so a fleet stays on one version."
  type        = string
  default     = "1.31"
}

variable "capabilities" {
  description = <<-EOT
    What the resulting ExecutionTarget advertises, and therefore what placement will route to it.

    This is the load-bearing input. A capability claimed here is a promise the cluster can run that class
    of work — a rule scoped to `pci-dss` will send card traffic to any target carrying it, and nothing
    downstream re-checks whether it is true.
  EOT
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
