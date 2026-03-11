project_name             = "devops"
registry_namespace       = "cesarnunezh"
postgres_image           = "cesarnunezh/database-service:prod-terraform"
postgres_user            = "postgres"
postgres_password        = "mysecretpassword"
postgres_db              = "database"
jenkins_http_port        = 8082
jenkins_agent_port       = 50002
jenkins_disable_security = true
postgres_host_port       = 5434
access_host              = "localhost"
minikube_driver          = "docker"
minikube_cpus            = 4
minikube_memory          = 6144
minikube_addons          = ["ingress"]
kubernetes_namespace     = "prod"

service_ports = {
  frontend = 3200
  products = 8270
  orders   = 8250
}
