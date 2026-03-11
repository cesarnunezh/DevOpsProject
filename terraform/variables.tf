variable "project_name" {
  description = "Short project identifier used in resource names."
  type        = string
}

variable "registry_namespace" {
  description = "Container registry namespace used by CI/CD."
  type        = string
}

variable "jenkins_image" {
  description = "Jenkins controller image."
  type        = string
  default     = null
  nullable    = true
}

variable "postgres_image" {
  description = "PostgreSQL image."
  type        = string
  default     = null
  nullable    = true
}

variable "postgres_user" {
  description = "PostgreSQL username."
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password."
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name."
  type        = string
}

variable "jenkins_http_port" {
  description = "Host port for Jenkins UI."
  type        = number
}

variable "jenkins_agent_port" {
  description = "Host port for Jenkins inbound agents."
  type        = number
}

variable "jenkins_home_source_volume" {
  description = "Optional existing Docker volume name to copy into the new Jenkins home volume before startup."
  type        = string
  default     = null
  nullable    = true
}

variable "jenkins_home_source_path" {
  description = "Optional host path to copy into the new Jenkins home volume before startup."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !(var.jenkins_home_source_volume != null && var.jenkins_home_source_path != null)
    error_message = "Set only one of jenkins_home_source_volume or jenkins_home_source_path."
  }
}

variable "jenkins_disable_security" {
  description = "Whether to force Jenkins to run without login by installing an init script in JENKINS_HOME."
  type        = bool
  default     = false
}

variable "jenkins_runtime_environment" {
  description = "Environment identity exposed inside the Jenkins runtime for CI/CD environment discovery."
  type        = string
  default     = null
  nullable    = true
}

variable "postgres_host_port" {
  description = "Host port for PostgreSQL."
  type        = number
}

variable "access_host" {
  description = "Hostname or IP used by Terraform outputs for reaching services from this environment."
  type        = string
  default     = "localhost"
}

variable "minikube_driver" {
  description = "Minikube driver."
  type        = string
}

variable "minikube_cpus" {
  description = "CPU count for the Minikube profile."
  type        = number
}

variable "minikube_memory" {
  description = "Memory in MB for the Minikube profile."
  type        = number
}

variable "minikube_kubernetes_version" {
  description = "Kubernetes version for Minikube."
  type        = string
  default     = null
  nullable    = true
}

variable "minikube_addons" {
  description = "List of Minikube addons to enable."
  type        = list(string)
  default     = []
}

variable "kubernetes_namespace" {
  description = "Default Kubernetes namespace name for the environment."
  type        = string
}

variable "service_ports" {
  description = "Base host ports for local services used later by CI/CD and Kubernetes manifests."
  type = object({
    frontend = number
    products = number
    orders   = number
  })
}
