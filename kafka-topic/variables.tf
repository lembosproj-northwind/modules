# The contract every resource module takes. See ../README.md — Lembos passes these without knowing
# which module it is calling, so a module that adds a required input here becomes unschedulable.

variable "name" {
  description = "The Resource's qualified name, e.g. ordering/orders-db."
  type        = string
}

variable "size_class" {
  description = "Relative sizing from the ResourceNeed: small, medium or large."
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.size_class)
    error_message = "size_class must be small, medium or large."
  }
}

variable "environment" {
  description = "The Environment's qualified name, e.g. northwind/prod."
  type        = string
}

variable "stamp" {
  description = "The Stamp this instance occupies, e.g. eu-west."
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Platform-supplied labels, merged into the provider's tags."
  type        = map(string)
  default     = {}
}

variable "bootstrap_servers" {
  description = "The shared cluster's brokers. Supplied by the EnvironmentProfile, not by the developer."
  type        = string
}

variable "cleanup_policy" {
  description = "delete or compact. A changelog topic wants compact; an event stream wants delete."
  type        = string
  default     = "delete"

  validation {
    condition     = contains(["delete", "compact"], var.cleanup_policy)
    error_message = "cleanup_policy must be delete or compact."
  }
}
