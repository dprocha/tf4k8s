resource "kubernetes_namespace" "tas" {
  metadata {
    name = "cf-system"
  }
}

resource "random_password" "gen" {
  length = 24
  special = false
}

data "local_file" "certs_vars" {
  filename = "${path.module}/certs.auto.tfvars"
}

data "template_file" "cf_values" {
  template = file("${path.module}/templates/cf-value-additions.yml")

  vars = {
    cf_admin_password = random_password.gen.result

    system_fullchain_certificate = element(split(" = ", element(split("\n", data.local_file.certs_vars.content), 0)), 1)
    system_private_key = element(split(" = ", element(split("\n", data.local_file.certs_vars.content), 1)), 1)
    workloads_fullchain_certificate = element(split(" = ", element(split("\n", data.local_file.certs_vars.content), 2)), 1)
    workloads_private_key = element(split(" = ", element(split("\n", data.local_file.certs_vars.content), 3)), 1)

    remove_resource_requirements = var.remove_resource_requirements
    add_metrics_server_components = var.add_metrics_server_components
    enable_load_balancer = var.enable_load_balancer
    use_external_dns_for_wildcard = var.use_external_dns_for_wildcard
    enable_automount_service_account_token = var.enable_automount_service_account_token
    metrics_server_prefer_internal_kubelet_address = var.metrics_server_prefer_internal_kubelet_address
    use_first_party_jwt_tokens = var.use_first_party_jwt_tokens
  }
}

data "local_file" "deployment_values_tmp" {
  filename = "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/configuration-values/deployment-values.tmp"
}

# PATCH #2
# Insert contents of cf-value-additions.yml within previously generated deployment-values.tmp at plaecholder
resource "local_file" "cf_values_rendered" {
  content  = replace(data.local_file.deployment_values_tmp.content, "((CF_VALUE_ADDITIONS))", data.template_file.cf_values.rendered)
  filename = "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/configuration-values/deployment-values.yml"
}

data "template_file" "app_registry_values" {
  template = file("${path.module}/templates/app-registry-values.yml")

  vars = {
    registry_domain     = var.registry_domain
    repository_prefix = var.repository_prefix
    registry_username   = var.registry_username
    registry_password   = var.registry_password
  }
}

resource "local_file" "app_registry_values_rendered" {
  content     = data.template_file.app_registry_values.rendered
  filename = "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/configuration-values/app-registry-values.yml"
}

data "template_file" "system_registry_values" {
  template = file("${path.module}/templates/system-registry-values.yml")

  vars = {
    pivnet_registry_hostname = var.pivnet_registry_hostname
    pivnet_username          = var.pivnet_username
    pivnet_password          = var.pivnet_password
  }
}

resource "local_file" "system_registry_values_rendered" {
  content     = data.template_file.system_registry_values.rendered
  filename = "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/configuration-values/system-registry-values.yml"
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

  depends_on = [
    local_file.tas4k8s_cert_rendered
  ]
}

data "k14s_ytt" "tas4k8s_ytt" {
  files = [
    "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/config",
    "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/configuration-values"
  ]

  debug_logs = true

  depends_on = [
    local_file.cf_values_rendered,
    local_file.app_registry_values_rendered,
    local_file.system_registry_values_rendered
  ]
}

data "k14s_kbld" "tas4k8s_config" {
  config_yaml = data.k14s_ytt.tas4k8s_ytt.result

  debug_logs = true
}

resource "local_file" "tas4k8s_config" {
  content     = data.k14s_kbld.tas4k8s_config.result
  filename = "${path.module}/${var.ytt_lib_dir}/tas4k8s/vendor/tas.yml"
}

resource "k14s_kapp" "tas4k8s" {
  app = "tas"
  namespace = "default"

  config_yaml = local_file.tas4k8s_config.content

  debug_logs = true

  depends_on = [
    k14s_kapp.tas4k8s_cert
  ]
}