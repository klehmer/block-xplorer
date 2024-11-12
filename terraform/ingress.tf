## This resource is included in terraform as it is needed to boostrap the ALB and must be provisioned before the DNS alias record can be created
resource "kubernetes_ingress_v1" "block_xplorer_ingress" {
  # This ingress should be provisioned after the load balancer controller to ensure the ALB is created successfully
  depends_on = [helm_release.aws_load_balancer_controller]

  metadata {
    name      = "block-xplorer-ingress"
    namespace = var.k8s_namespace
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/target-type"     = "instance"
      "alb.ingress.kubernetes.io/certificate-arn" = module.acm.acm_certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.domain_name
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "block-xplorer-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts = [var.domain_name]
    }
  }
}
