resource "docker_image" "postgres" {
  name         = var.postgres_image
  keep_locally = true
}

resource "docker_container" "postgres" {
  name  = "${var.name_prefix}-postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=${var.postgres_db}",
  ]

  ports {
    internal = 5432
    external = var.host_port
  }

  mounts {
    target = "/var/lib/postgresql/data"
    type   = "volume"
    source = var.volume_name
  }

  networks_advanced {
    name = var.network_name
  }

  restart = "unless-stopped"
}
