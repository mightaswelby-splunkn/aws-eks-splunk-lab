data "aws_route53_zone" "selected" {
  name         = var.domain_base
  private_zone = false
}

