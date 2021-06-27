
resource "kubernetes_namespace" "cert-manager" {
  metadata {

    name = "cert-manager"
  }
}

module "cert-manager" {
  depends_on = [
    kubernetes_namespace.cert-manager
  ]
  source  = "basisai/cert-manager/helm"
  version = "0.1.1"
  # insert the 3 required variables here
  chart_namespace = "cert-manager"
  chart_version   = ""
}

resource "kubectl_manifest" "ca_issuer" {
  depends_on = [
    module.cert-manager
  ]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
  namespace: cert-manager
spec:
  ca:
    secretName: ca-key-pair
YAML
}



