
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio_operator" {
  name  = "istio-operator"
  chart = "istio/manifests/charts/istio-operator"

  depends_on = [module.eks, kubernetes_namespace.istio_system, module.load_balancer_controller]

  set {
    name  = "operatorNamespace"
    value = "istio-operator"
  }

}

data "kubectl_path_documents" "istio" {
  pattern = "manifests/istio/*.yml"
  vars = {
    certarn      = aws_acm_certificate_validation.cert.certificate_arn
    domain_name  = local.domain_name
    cluster_name = local.cluster_name
  }
}

resource "kubectl_manifest" "istio" {
  depends_on = [
    helm_release.istio_operator
  ]
  count     = length(data.kubectl_path_documents.istio.documents)
  yaml_body = element(data.kubectl_path_documents.istio.documents, count.index)


}

data "kubectl_path_documents" "istio_addons" {
  pattern = "istio/samples/addons/*.yaml"
  disable_template = true
}

resource "kubectl_manifest" "istio_addons" {
  depends_on = [
    helm_release.istio_operator
  ]
  count     = length(data.kubectl_path_documents.istio_addons.documents)
  yaml_body = element(data.kubectl_path_documents.istio_addons.documents, count.index)


}

