
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio_operator" {
  name  = "istio-operator"
  chart = "istio/manifests/charts/istio-operator"

  depends_on = [module.eks, kubernetes_namespace.istio_system, module.load_balancer_controller]

  set {
    name  = "operatorNamespace"
    value = "istio-operator"
  }

}

resource "kubectl_manifest" "istio" {
  depends_on = [
    helm_release.istio_operator
  ]
  yaml_body = <<YAML
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: demo

  meshConfig:
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: 1 #--Define upstream proxy count
    accessLogFile: /dev/stdout
    enableTracing: true
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          serviceAnnotations:
            service.beta.kubernetes.io/aws-load-balancer-connection-draining-enabled: "false" #--True by default, uses ELB
            service.beta.kubernetes.io/aws-load-balancer-internal: "false" #--True by default, uses ELB
            service.beta.kubernetes.io/aws-load-balancer-type: "external"
            service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${aws_acm_certificate_validation.cert.certificate_arn}
            service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10"
            service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
            service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443,8089,8088"
            #service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
            service.beta.kubernetes.io/aws-load-balancer-ip-address-type: ipv4
            external-dns.alpha.kubernetes.io/hostname: "${local.domain_name}, *.${local.domain_name}"
            external-dns.alpha.kubernetes.io/ttl: "300" #optional
            service.beta.kubernetes.io/aws-load-balancer-name: "${local.cluster_name}"
            service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: preserve_client_ip.enabled=false
            service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: proxy_protocol_v2.enabled=true

          service:
            ports:
              - name: https
                nodePort: 31923
                port: 443
                protocol: TCP
                targetPort: 8443
              - name: http2
                nodePort: 31115
                port: 80
                protocol: TCP
                targetPort: 8080
             
              - name: https-mgmt
                nodePort: 30071
                port: 8089
                protocol: TCP
                targetPort: 15444
              - name: https-hec
                nodePort: 30072
                port: 8088
                protocol: TCP
                targetPort: 15445
              - name: tls-s2s
                nodePort: 30074
                port: 9998
                protocol: TCP
                targetPort: 15447
    cni:
      enabled: true
  values:
    cni:
      excludeNamespaces:
        - istio-system
        - kube-system
      logLevel: info

YAML
}
