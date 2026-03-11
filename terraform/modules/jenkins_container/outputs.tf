output "container_name" {
  description = "Jenkins container name."
  value       = docker_container.jenkins.name
}

output "url" {
  description = "Jenkins URL."
  value       = "http://${var.access_host}:${var.http_port}"
}

output "http_port" {
  description = "Host port mapped to Jenkins."
  value       = var.http_port
}

output "home_volume" {
  description = "Jenkins Docker volume name."
  value       = var.volume_name
}
