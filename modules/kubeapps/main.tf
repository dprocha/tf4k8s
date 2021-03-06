resource "kubernetes_namespace" "kubeapps" {
  metadata {
    name = "kubeapps"
  }
}

data "template_file" "kubeapps_config" {
  template = file("${path.module}/templates/${var.ingress}/values.yml")

  vars = {
    kubeapps_domain  = local.kubeapps_domain
  }
}

resource "helm_release" "kubeapps" {

  name       = "kubeapps"
  namespace  = kubernetes_namespace.kubeapps.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kubeapps"
  version    = "3.9.2"

  values = [data.template_file.kubeapps_config.rendered]
}
