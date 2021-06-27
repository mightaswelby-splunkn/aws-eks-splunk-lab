
module "load_balancer_controller" {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-lb-controller.git"

  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  cluster_name                     = module.eks.cluster_id
  depends_on                       = [module.eks, aws_eks_addon.cni]
}


#annotations:
#    eks.amazonaws.com/role-arn: arn:aws:iam::174701313045:role/eksctl-spl-guru-v2-addon-iamserviceaccount-k-Role1-1BYJ5QK6PMSKC
#helm install aws-load-balancer-controller eks/aws-load-balancer-controller 
#-n kube-system --set clusterName=<cluster-name> 
#--set serviceAccount.create=false 
#--set serviceAccount.name=aws-load-balancer-controller


# resource "helm_release" "aws-load-balancer-controller" {
#   name       = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "eks/aws-load-balancer-controller"

#   set {
#     name  = "clusterName"
#     value = local.cluster_name

#   }
#   set {
#     name  = "serviceAccount.create"
#     value = "false"
#   }
#   set {
#     name = "serviceAccount.annotations"
#     value = {
#       "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_sa.arn
#     }
#   }
#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }
# }
