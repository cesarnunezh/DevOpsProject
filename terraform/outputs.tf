output "environment" {
  description = "Active Terraform workspace."
  value       = local.environment
}

output "name_prefix" {
  description = "Environment-specific prefix used for resource names."
  value       = local.name_prefix
}

output "docker_registry_namespace" {
  description = "Container registry namespace used by CI/CD."
  value       = var.registry_namespace
}

output "image_repository_prefix" {
  description = "Registry prefix used to construct image repository names."
  value       = local.image_repository_prefix
}

output "docker_network_name" {
  description = "Shared Docker network name."
  value       = module.local_dev.network_name
}

output "jenkins_url" {
  description = "Jenkins controller URL."
  value       = module.jenkins_container.url
}

output "jenkins_port" {
  description = "Jenkins host port."
  value       = module.jenkins_container.http_port
}

output "postgres_host" {
  description = "PostgreSQL host."
  value       = module.postgres_container.host
}

output "postgres_port" {
  description = "PostgreSQL host port."
  value       = module.postgres_container.port
}

output "postgres_db" {
  description = "PostgreSQL database name."
  value       = module.postgres_container.db_name
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string for local tooling and CI/CD."
  value       = module.postgres_container.connection_string
  sensitive   = true
}

output "minikube_profile" {
  description = "Minikube profile name."
  value       = module.minikube.profile
}

output "minikube_kubeconfig_context" {
  description = "Kubeconfig context for the Minikube profile."
  value       = module.minikube.kubeconfig_context
}

output "minikube_kubeconfig_path" {
  description = "Kubeconfig path used by the local Minikube profile."
  value       = module.minikube.kubeconfig_path
}

output "minikube_cluster_ip" {
  description = "Minikube cluster IP."
  value       = module.minikube.cluster_ip
}

output "kubernetes_namespace" {
  description = "Default namespace name to use in the Kubernetes phase."
  value       = var.kubernetes_namespace
}

output "service_base_urls" {
  description = "Base URLs reserved for local services."
  value = {
    frontend = "http://${var.access_host}:${var.service_ports.frontend}"
    products = "http://${var.access_host}:${var.service_ports.products}"
    orders   = "http://${var.access_host}:${var.service_ports.orders}"
    jenkins  = module.jenkins_container.url
  }
}
