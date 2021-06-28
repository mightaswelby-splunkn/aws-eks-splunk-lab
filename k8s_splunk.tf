
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
