output "profile" {
  description = "Minikube profile name."
  value       = local.metadata.profile
}

output "cluster_ip" {
  description = "Minikube cluster IP."
  value       = local.metadata.cluster_ip
}

output "kubeconfig_context" {
  description = "Kubeconfig context name."
  value       = local.metadata.kubeconfig_context
}

output "kubeconfig_path" {
  description = "Kubeconfig path."
  value       = local.metadata.kubeconfig_path
}
