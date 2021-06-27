locals {
  cluster_name = random_pet.deployment.id
  domain_name  = "${random_pet.deployment.id}.${var.domain_base}"
}

resource "random_pet" "deployment" {
  length    = 2
  separator = "-"
}

