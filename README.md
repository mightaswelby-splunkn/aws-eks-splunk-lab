Expected env
 EKS 1.20
 terraform 1.x
 domain is managed by route53

terraform init
terraform apply


TODO

My lab domain is hard coded replace spl.guru with a domain you control

* Create EKS Cluster with CNI plugin
* Install and configure istio, cert-manager, cluster-autoscaler, kiali
* Creates and uses a new certificate with ACM
* Uses NLB not legacy AWS ELB classic
