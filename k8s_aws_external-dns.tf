module "external_dns" {
  source                           = "git::https://github.com/DNXLabs/terraform-aws-eks-external-dns.git"
  namespace                        = "kube-system"
  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  policy_allowed_zone_ids = [data.aws_route53_zone.selected.zone_id]
  settings = {
    "policy" = "upsert-only" # Modify how DNS records are sychronized between sources and providers.
  }
}
