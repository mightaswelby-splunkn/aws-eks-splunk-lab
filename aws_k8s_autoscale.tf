resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  policy_arn = aws_iam_policy.worker_autoscaling.arn
  role       = module.eks.worker_iam_role_name
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${module.eks.cluster_id}"
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
  #path        = var.iam_path
  #tags        = var.tags
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "helm_release" "cluster-autoscaler" {
  name  = "cluster-autoscaler"
  namespace = "kube-system"
  chart = "cluster-autoscaler"
  repository  = "https://kubernetes.github.io/autoscaler"

  depends_on = [aws_iam_role_policy_attachment.workers_autoscaling]

  set {
    name  = "awsRegion"
    value = var.region
  }
  set {
      name = "cloudProvider"
      value = "aws"
  }
  set {
    name  = "rbac.create"
    value = "true"
  }
#   set {
#     name  = "rbac.serviceAccount.name"
#     value = module.cluster_autoscaler.iam_role_cluster_autoscaler_name
#   }
#   set {
#     name  = "rbac.serviceAccount.eks.amazonaws.com/role-arn"
#     value = module.cluster_autoscaler.iam_role_cluster_autoscaler_arn
#   }
  set {
    name  = "autoDiscovery.clusterName"
    value = local.cluster_name
  }
  set {
    name  = "autoDiscovery.enabled"
    value = true
  }

}
