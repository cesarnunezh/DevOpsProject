variable "profile" {
  description = "Minikube profile name."
  type        = string
}

variable "driver" {
  description = "Minikube driver."
  type        = string
}

variable "cpus" {
  description = "CPU count for Minikube."
  type        = number
}

variable "memory" {
  description = "Memory in MB for Minikube."
  type        = number
}

variable "kubernetes_version" {
  description = "Kubernetes version for Minikube."
  type        = string
}

variable "addons" {
  description = "Addons to enable on the profile."
  type        = list(string)
  default     = []
}
