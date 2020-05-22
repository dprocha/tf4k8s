resource "kubernetes_namespace" "tas" {
  metadata {
    name = "cf-system"
  }
}

resource "random_password" "gen" {
  length = 24
  special = false
}

data "template_file" "tas4k8s_config" {
  template = file("${path.module}/templates/config.yml")

  vars = {
    system_domain = local.system_domain
    app_domain = local.app_domain

    cf_admin_password = random_password.gen.result

    registry_domain     = var.registry_domain
    registry_repository = var.registry_repository
    registry_username   = var.registry_username
    registry_password   = var.registry_password
  }
}

resource "local_file" "tas4k8s_config_rendered" {
  content     = data.template_file.tas4k8s_config.rendered
  filename = "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/config-rendered.yml"
}

data "template_file" "tas4k8s_cert" {
  template = file("${path.module}/templates/cert.yml")

  vars = {
    system_domain = local.system_domain
    namespace     = kubernetes_namespace.tas.metadata[0].name
  }
}

resource "local_file" "tas4k8s_cert_rendered" {
  content     = data.template_file.tas4k8s_cert.rendered
  filename = "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/cert-rendered.yml"
}

resource "k14s_kapp" "tas4k8s_cert" {
  app = "tas4k8s-cert"

  namespace = "default"

  config_yaml = data.template_file.tas4k8s_cert.rendered

  debug_logs = true

  deploy {
    raw_options = ["--dangerous-allow-empty-list-of-resources=true"]
  }

  depends_on = [
    local_file.tas4k8s_cert_rendered
  ]
}

data "k14s_ytt" "tas4k8s_ytt" {
  files = [
    "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/config/_deps/cf-for-k8s/config",
    "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/config-optional/use-external-dns-for-wildcard.yml"
  ]

  debug_logs = true

  config_yaml = data.template_file.tas4k8s_config.rendered

  depends_on = [
    local_file.tas4k8s_config_rendered
  ]
}

resource "local_file" "tas4k8s_ytt" {
  content = data.k14s_ytt.tas4k8s_ytt.result
  filename = "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/config-ytt.yml"
}

resource "k14s_kapp" "tas4k8s" {
  app = "tas"
  namespace = "default"

  config_yaml = data.k14s_ytt.tas4k8s_ytt.result

  debug_logs = true

  deploy {
    raw_options = ["--dangerous-allow-empty-list-of-resources=true"]
  }

  depends_on = [
    k14s_kapp.tas4k8s_cert,
    local_file.tas4k8s_ytt
  ]

}