resource "kubernetes_namespace" "splunk-operator" {
  metadata {
    name = "splunk-operator"
  }
}

data "kubectl_path_documents" "splunk-operator" {
  pattern = "manifests/splunk-operator/*.yml"
}

resource "kubectl_manifest" "splunk-operator" {
  depends_on = [
    kubernetes_namespace.splunk-operator
  ]
  count     = length(data.kubectl_path_documents.splunk-operator.documents)
  yaml_body = element(data.kubectl_path_documents.splunk-operator.documents, count.index)
}


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


resource "kubernetes_namespace" "splunk-ci" {
  metadata {
    name = "splunk-ci"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

data "kubectl_path_documents" "splunk-ci-rolebinding" {
  pattern = "manifests/splunk-operator-rolebinding/rolebinding.yml"
  vars = {
    namespace = "splunk-ci"
  }
}

resource "kubectl_manifest" "splunk-ci" {
  depends_on = [
    kubernetes_namespace.splunk-ci
  ]
  count     = length(data.kubectl_path_documents.splunk-ci-rolebinding.documents)
  yaml_body = element(data.kubectl_path_documents.splunk-ci-rolebinding.documents, count.index)

}
