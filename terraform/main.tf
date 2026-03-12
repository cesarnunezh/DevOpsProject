module "local_dev" {
  source = "./modules/local_dev"

  name_prefix = local.name_prefix
  labels      = local.labels
}

module "postgres_container" {
  source = "./modules/postgres_container"

  name_prefix       = local.name_prefix
  labels            = local.labels
  network_name      = module.local_dev.network_name
  volume_name       = module.local_dev.postgres_volume_name
  postgres_image    = var.postgres_image
  postgres_user     = var.postgres_user
  postgres_password = var.postgres_password
  postgres_db       = var.postgres_db
  host_port         = var.postgres_host_port
  access_host       = var.access_host
}

module "jenkins_container" {
  source = "./modules/jenkins_container"

  name_prefix         = local.name_prefix
  labels              = local.labels
  network_name        = module.local_dev.network_name
  volume_name         = module.local_dev.jenkins_volume_name
  jenkins_image       = local.jenkins_image
  http_port           = var.jenkins_http_port
  agent_port          = var.jenkins_agent_port
  access_host         = var.access_host
  runtime_environment = local.jenkins_runtime_environment
  source_volume_name  = var.jenkins_home_source_volume
  source_path         = var.jenkins_home_source_path
  disable_security    = var.jenkins_disable_security
  kube_dir_path       = local.jenkins_kube_dir_path
  minikube_dir_path   = local.jenkins_minikube_dir_path
  kubeconfig_path     = module.minikube.kubeconfig_path
  kube_context        = module.minikube.kubeconfig_context
}

module "minikube" {
  source = "./modules/minikube"

  profile            = "${local.name_prefix}-minikube"
  driver             = var.minikube_driver
  cpus               = var.minikube_cpus
  memory             = var.minikube_memory
  kubernetes_version = local.minikube_kubernetes_version
  addons             = var.minikube_addons
}
