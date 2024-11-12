# Get the Route 53 Hosted Zone ID for the domain
data "aws_route53_zone" "dns_zone" {
  name         = var.domain_name
  private_zone = false
}

# Get the ALB created by the ingress
data "aws_lb" "alb" {
  tags = {
    "elbv2.k8s.aws/cluster"    = module.eks.cluster_name
    "ingress.k8s.aws/resource" = "LoadBalancer"
    "ingress.k8s.aws/stack"    = "${var.k8s_namespace}/block-xplorer-ingress"
  }
}

# Create an A record to map the domain to the ELB IP address
resource "aws_route53_record" "app_record" {
  # must be provisioned after the ingress or the ALB will not exist
  depends_on = [kubernetes_ingress_v1.block_xplorer_ingress]

  zone_id = data.aws_route53_zone.dns_zone.id
  name    = var.domain_name
  type    = "A"
  alias {
    evaluate_target_health = true
    name                   = data.aws_lb.alb.dns_name
    zone_id                = data.aws_lb.alb.zone_id
  }
}
