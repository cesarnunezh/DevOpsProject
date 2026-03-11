project_name             = "devops"
registry_namespace       = "cesarnunezh"
postgres_image           = "cesarnunezh/database-service:dev-terraform"
postgres_user            = "postgres"
postgres_password        = "mysecretpassword"
postgres_db              = "database"
jenkins_http_port        = 8080
jenkins_agent_port       = 50000
jenkins_disable_security = true
postgres_host_port       = 5432
access_host              = "localhost"
minikube_driver          = "docker"
minikube_cpus            = 2
minikube_memory          = 4096
minikube_addons          = ["ingress"]
kubernetes_namespace     = "dev"

service_ports = {
  frontend = 3000
  products = 8070
  orders   = 8050
}
