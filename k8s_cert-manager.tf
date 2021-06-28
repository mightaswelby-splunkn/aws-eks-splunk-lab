
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
  wait      = true
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

resource "tls_private_key" "ca" {
  algorithm   = "RSA"
  ecdsa_curve = "4096"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = local.domain_name
    organization = local.cluster_name
  }

  validity_period_hours = 21900
  is_ca_certificate     = true
  set_subject_key_id    = true

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}


resource "kubernetes_secret" "ca_cert" {
  metadata {
    name      = "ca-key-pair"
    namespace = "cert-manager"
  }

  type = "kubernetes.io/tls"

  data = {
    #    "tls.crt" = "${base64encode("tls_self_signed_cert.ca.cert_pem")}"
    #    "tls.key" = "${base64encode("tls_private_key.ca.private_key_pem")}"
    "tls.crt" = "${tls_self_signed_cert.ca.cert_pem}"
    "tls.key" = "${tls_private_key.ca.private_key_pem}"
  }
}