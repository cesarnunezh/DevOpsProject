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
  description = "Docker volume name for database persistence."
  type        = string
}

variable "postgres_image" {
  description = "PostgreSQL image reference."
  type        = string
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

variable "host_port" {
  description = "Host port mapped to PostgreSQL."
  type        = number
}

variable "access_host" {
  description = "Hostname or IP used in PostgreSQL access outputs."
  type        = string
}
