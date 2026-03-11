locals {
  seed_from_volume     = var.source_volume_name != null
  seed_from_path       = var.source_path != null
  seed_volume_cmd      = <<-EOT
    docker run --rm \
      --user 0:0 \
      --entrypoint sh \
      -v "${var.source_volume_name != null ? var.source_volume_name : ""}:/source:ro" \
      -v "${var.volume_name}:/target" \
      "${var.jenkins_image}" \
      -c "cp -a /source/. /target/"
  EOT
  seed_path_cmd        = <<-EOT
    docker run --rm \
      --user 0:0 \
      --entrypoint sh \
      -v "${var.source_path != null ? var.source_path : ""}:/source:ro" \
      -v "${var.volume_name}:/target" \
      "${var.jenkins_image}" \
      -c "cp -a /source/. /target/"
  EOT
  disable_security_cmd = <<-EOT
    docker run --rm \
      --user 0:0 \
      --entrypoint sh \
      -v "${var.volume_name}:/target" \
      "${var.jenkins_image}" \
      -c 'mkdir -p /target/init.groovy.d && cat > /target/init.groovy.d/disable-security.groovy <<'"'"'EOF'"'"'
import jenkins.model.Jenkins
import hudson.security.SecurityRealm
import hudson.security.AuthorizationStrategy

def instance = Jenkins.get()
instance.setSecurityRealm(SecurityRealm.NO_AUTHENTICATION)
instance.setAuthorizationStrategy(new AuthorizationStrategy.Unsecured())
instance.save()
EOF
chown -R 1000:1000 /target/init.groovy.d'
  EOT
  fix_permissions_cmd  = <<-EOT
    docker run --rm \
      --user 0:0 \
      --entrypoint sh \
      -v "${var.volume_name}:/target" \
      "${var.jenkins_image}" \
      -c 'mkdir -p /target && chown -R 1000:1000 /target'
  EOT
}

resource "docker_image" "jenkins" {
  name         = var.jenkins_image
  keep_locally = true
}

resource "null_resource" "seed_home" {
  count = local.seed_from_volume || local.seed_from_path ? 1 : 0

  triggers = {
    destination_volume = var.volume_name
    source_volume      = var.source_volume_name != null ? var.source_volume_name : ""
    source_path        = var.source_path != null ? var.source_path : ""
  }

  provisioner "local-exec" {
    command     = local.seed_from_volume ? local.seed_volume_cmd : local.seed_path_cmd
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "configure_home" {
  count = var.disable_security ? 1 : 0

  triggers = {
    destination_volume = var.volume_name
    disable_security   = tostring(var.disable_security)
  }

  provisioner "local-exec" {
    command     = local.disable_security_cmd
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [null_resource.seed_home]
}

resource "null_resource" "fix_home_permissions" {
  triggers = {
    destination_volume = var.volume_name
    jenkins_image      = var.jenkins_image
  }

  provisioner "local-exec" {
    command     = local.fix_permissions_cmd
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [null_resource.seed_home, null_resource.configure_home]
}

resource "docker_container" "jenkins" {
  name  = "${var.name_prefix}-jenkins"
  image = docker_image.jenkins.image_id

  env = concat(
    ["JENKINS_RUNTIME_ENV=${var.runtime_environment}"],
    var.disable_security ? ["JAVA_OPTS=-Djenkins.install.runSetupWizard=false"] : []
  )

  ports {
    internal = 8080
    external = var.http_port
  }

  ports {
    internal = 50000
    external = var.agent_port
  }

  mounts {
    target = "/var/jenkins_home"
    type   = "volume"
    source = var.volume_name
  }

  networks_advanced {
    name = var.network_name
  }

  restart = "unless-stopped"

  depends_on = [null_resource.fix_home_permissions]
}
