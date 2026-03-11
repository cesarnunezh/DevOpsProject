locals {
  metadata_dir  = "${path.module}/generated"
  metadata_path = "${local.metadata_dir}/${var.profile}.json"
  addons_arg    = join(" ", var.addons)
}

resource "null_resource" "minikube_profile" {
  triggers = {
    profile            = var.profile
    driver             = var.driver
    cpus               = tostring(var.cpus)
    memory             = tostring(var.memory)
    kubernetes_version = var.kubernetes_version
    addons             = join(",", var.addons)
  }

  provisioner "local-exec" {
    command     = <<-EOT
      mkdir -p "${local.metadata_dir}"
      minikube delete -p "${var.profile}" || true
      minikube start \
        --profile="${var.profile}" \
        --driver="${var.driver}" \
        --cpus="${var.cpus}" \
        --memory="${var.memory}" \
        --kubernetes-version="${var.kubernetes_version}" \
        --delete-on-failure \
        --install-addons=false \
        --wait=apiserver,system_pods,node_ready
      kubectl --context="${var.profile}" wait --for=condition=Ready node --all --timeout=180s
      for addon in default-storageclass storage-provisioner ${local.addons_arg}; do
        minikube addons enable "$addon" -p "${var.profile}"
      done
      cat > "${local.metadata_path}" <<EOF
      {"profile":"${var.profile}","cluster_ip":"$(minikube ip -p "${var.profile}")","kubeconfig_context":"${var.profile}","kubeconfig_path":"$HOME/.kube/config"}
      EOF
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<-EOT
      minikube delete -p "${self.triggers.profile}" || true
      rm -f "${path.module}/generated/${self.triggers.profile}.json"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

locals {
  default_metadata = {
    profile            = var.profile
    cluster_ip         = ""
    kubeconfig_context = var.profile
    kubeconfig_path    = pathexpand("~/.kube/config")
  }
  metadata = jsondecode(try(file(local.metadata_path), jsonencode(local.default_metadata)))
}
