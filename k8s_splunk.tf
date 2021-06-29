
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

resource "aws_iam_user" "splunk" {
  name = "${local.cluster_name}-splunk-s1-idxc"
  path = "/"

}

resource "aws_iam_access_key" "splunk" {
  user = aws_iam_user.splunk.name
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.splunk.name
  policy_arn = aws_iam_policy.s3_splunk_policy.arn
}


resource "kubernetes_secret" "app-registry" {
  metadata {
    name      = "app-registry"
    namespace = kubernetes_namespace.splunk.metadata[0].name
  }

  data = {
    ORAS_TOKEN = var.oras_token
    ORAS_USER  = var.oras_user
  }
}

resource "kubernetes_secret" "s1_idxc_s3" {
  metadata {
    name      = "s1-idxc-s3"
    namespace = kubernetes_namespace.splunk.metadata[0].name
  }

  data = {
    s3_access_key = aws_iam_access_key.splunk.id
    s3_secret_key = aws_iam_access_key.splunk.secret
  }
}


resource "kubernetes_config_map" "splunk_license" {
  metadata {
    name      = "splunk-licenses"
    namespace = kubernetes_namespace.splunk.metadata[0].name
  }

  data = {
    "enterprise.lic" = "${file("${path.module}/.splunk_licenses/enterprise.lic")}"
  }

}


data "kubectl_path_documents" "splunk" {
  pattern = "manifests/splunk/*.yml"
  vars = {
    ORAS_OBJECTS      = var.oras_objects
    DOMAIN_NAME       = local.domain_name
    SMARTSTORE_BUCKET = module.s3_bucket_splunk.s3_bucket_bucket_domain_name
  }

}

resource "kubectl_manifest" "splunk" {
  depends_on = [
    kubectl_manifest.splunk-rolebinding,
    kubernetes_config_map.splunk_license,
    data.kubectl_path_documents.splunk
  ]

  override_namespace = kubernetes_namespace.splunk.metadata[0].name
  count              = length(data.kubectl_path_documents.splunk.documents)
  yaml_body          = element(data.kubectl_path_documents.splunk.documents, count.index)

}