
resource "kubernetes_namespace" "splunk" {
  metadata {
    name = "splunk"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

data "kubectl_path_documents" "splunk-rolebinding" {
  pattern = "manifests/splunk-operator-rolebinding/rolebinding.yml"
  vars = {
    namespace = "splunk"
  }
}

resource "kubectl_manifest" "splunk-rolebinding" {
  depends_on = [
    kubernetes_namespace.splunk
  ]
  count     = length(data.kubectl_path_documents.splunk-rolebinding.documents)
  yaml_body = element(data.kubectl_path_documents.splunk-rolebinding.documents, count.index)

}

resource "kubernetes_secret" "app_registry" {
  metadata {
    name      = "app-registry"
    namespace = kubernetes_namespace.splunk.metadata[0].name
  }

  data = {
    ORAS_TOKEN = var.oras_token
    ORAS_USER  = var.oras_user
  }
}


data "kubectl_path_documents" "splunk" {
  pattern = "manifests/splunk/*.yml"
  vars = {
    ORAS_OBJECTS = var.oras_objects
    DOMAIN_NAME = local.domain_name
  }

}

resource "kubectl_manifest" "splunk" {
  depends_on = [
    kubectl_manifest.splunk-rolebinding
  ]
  override_namespace = kubernetes_namespace.splunk.metadata[0].name
  count     = length(data.kubectl_path_documents.splunk.documents)
  yaml_body = element(data.kubectl_path_documents.splunk.documents, count.index)

}