resource "docker_network" "shared" {
  name = "${var.name_prefix}-network"
}

resource "docker_volume" "jenkins_home" {
  name = "${var.name_prefix}-jenkins-home"
}

resource "docker_volume" "postgres_data" {
  name = "${var.name_prefix}-postgres-data"
}
