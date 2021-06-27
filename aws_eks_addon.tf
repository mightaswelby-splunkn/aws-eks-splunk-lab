resource "aws_eks_addon" "cni" {
  cluster_name      = data.aws_eks_cluster.cluster.name
  addon_name        = "vpc-cni"
  addon_version     = "v1.8.0-eksbuild.1"
  resolve_conflicts = "OVERWRITE"
}