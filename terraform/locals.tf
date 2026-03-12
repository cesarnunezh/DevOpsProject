locals {
  shared_versions = jsondecode(file("${path.module}/../config/versions.json"))

  environment = terraform.workspace
  name_prefix = "${var.project_name}-${local.environment}"
  jenkins_image = coalesce(
    var.jenkins_image,
    local.shared_versions.infra.jenkins_image
  )
  minikube_kubernetes_version = coalesce(
    var.minikube_kubernetes_version,
    local.shared_versions.infra.minikube_kubernetes_version
  )
  jenkins_runtime_environment = coalesce(
    var.jenkins_runtime_environment,
    local.environment
  )
  jenkins_kube_dir_path = coalesce(
    var.jenkins_kube_dir_path,
    pathexpand("~/.kube")
  )
  jenkins_minikube_dir_path = coalesce(
    var.jenkins_minikube_dir_path,
    pathexpand("~/.minikube")
  )

  labels = {
    project     = var.project_name
    environment = local.environment
    managed_by  = "terraform"
  }

  image_repository_prefix = var.registry_namespace
}
