# The contract every component module takes — the Terraform spelling of the component charts'
# values.yaml, so one ComponentSpecVersion renders to either without the spec knowing which.

variable "name" {
  description = "The Component's qualified name, e.g. notifications/email-dispatch."
  type        = string
}

variable "environment" {
  description = "The Environment's qualified name, e.g. northwind/prod."
  type        = string
}

variable "stamp" {
  description = "The Stamp this instance occupies."
  type        = string
  default     = "default"
}

variable "artifact_uri" {
  description = "Where the built artifact lives — the bundle this deployment places."
  type        = string
}

variable "artifact_digest" {
  description = "The pinned content digest. A deployment pins what it resolved; a tag can move under it."
  type        = string
  default     = ""
}

variable "config" {
  description = "The merged ConfigSet, projected as environment variables."
  type        = map(string)
  default     = {}
}

variable "resource_bindings" {
  description = "One entry per ResourceNeed, keyed by its handle, holding where the credential is."
  type        = map(object({ secret_ref = string }))
  default     = {}
}

variable "size_class" {
  description = "Relative sizing from the ComponentSpec."
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large"], var.size_class)
    error_message = "size_class must be small, medium or large."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "runtime" {
  description = "Lambda runtime identifier. Pinned by the blueprint."
  type        = string
  default     = "dotnet8"
}

variable "handler" {
  description = "Entry point, in the runtime's own spelling."
  type        = string
  default     = "bootstrap"
}
