project_name             = "devops"
registry_namespace       = "cesarnunezh"
postgres_image           = "cesarnunezh/database-service:staging-terraform"
postgres_user            = "postgres"
postgres_password        = "mysecretpassword"
postgres_db              = "database"
jenkins_http_port        = 8081
jenkins_agent_port       = 50001
jenkins_disable_security = true
postgres_host_port       = 5433
access_host              = "localhost"
minikube_driver          = "docker"
minikube_cpus            = 2
minikube_memory          = 5120
minikube_addons          = ["ingress"]
kubernetes_namespace     = "staging"

service_ports = {
  frontend = 3100
  products = 8170
  orders   = 8150
}
