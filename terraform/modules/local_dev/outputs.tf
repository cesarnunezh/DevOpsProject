output "network_name" {
  description = "Shared Docker network name."
  value       = docker_network.shared.name
}

output "jenkins_volume_name" {
  description = "Docker volume name for Jenkins home."
  value       = docker_volume.jenkins_home.name
}

output "postgres_volume_name" {
  description = "Docker volume name for PostgreSQL data."
  value       = docker_volume.postgres_data.name
}
