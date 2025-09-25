variable "environment_name" {
  description = "Name of the environment"
  type        = string
  default     = "retail-store"
}

variable "istio_enabled" {
  description = "Boolean value that enables istio."
  type        = bool
  default     = false
}

variable "opentelemetry_enabled" {
  description = "Boolean value that enables OpenTelemetry."
  type        = bool
  default     = false
}

# variable "cluster_version" {
#   description = "Kubernetes version for EKS cluster"
#   type        = string
#   default     = "1.30"
# }
