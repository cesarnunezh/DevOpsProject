variable "name_prefix" {
  description = "Environment-scoped resource name prefix."
  type        = string
}

variable "labels" {
  description = "Standard metadata labels."
  type        = map(string)
}

variable "network_name" {
  description = "Docker network to attach the container to."
  type        = string
}

variable "volume_name" {
  description = "Docker volume name for Jenkins home."
  type        = string
}

variable "jenkins_image" {
  description = "Jenkins controller image."
  type        = string
}

variable "http_port" {
  description = "Host port mapped to Jenkins UI."
  type        = number
}

variable "agent_port" {
  description = "Host port mapped to Jenkins agent listener."
  type        = number
}

variable "access_host" {
  description = "Hostname or IP used in Jenkins access outputs."
  type        = string
}

variable "runtime_environment" {
  description = "Environment identity exposed inside the Jenkins controller runtime."
  type        = string
}

variable "source_volume_name" {
  description = "Optional Docker volume name to seed Jenkins home from."
  type        = string
  default     = null
  nullable    = true
}

variable "source_path" {
  description = "Optional host path to seed Jenkins home from."
  type        = string
  default     = null
  nullable    = true
}

variable "disable_security" {
  description = "Whether to force Jenkins security off during startup."
  type        = bool
  default     = false
}
