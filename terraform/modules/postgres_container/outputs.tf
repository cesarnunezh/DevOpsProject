output "container_name" {
  description = "PostgreSQL container name."
  value       = docker_container.postgres.name
}

output "host" {
  description = "Host used to reach PostgreSQL."
  value       = var.access_host
}

output "port" {
  description = "Host port mapped to PostgreSQL."
  value       = var.host_port
}

output "db_name" {
  description = "PostgreSQL database name."
  value       = var.postgres_db
}

output "connection_string" {
  description = "Connection string for local PostgreSQL."
  value       = "postgresql://${var.postgres_user}:${var.postgres_password}@${var.access_host}:${var.host_port}/${var.postgres_db}"
  sensitive   = true
}
