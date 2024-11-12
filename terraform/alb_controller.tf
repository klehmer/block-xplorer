## These resources are necessary for provisioning the AWS Load Balancer Controller in K8s which handles bootstrapping the ALB using the ingress resource
data "aws_caller_identity" "current" {}

# Declare the aws_iam_policy_document for the ALB controller policy
data "aws_iam_policy_document" "alb_controller_policy" {
  statement {
    actions = [
      # ACM permissions for managing SSL certificates
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",

      # ELB permissions for creating and managing load balancers
      "elasticloadbalancing:*",

      # EC2 permissions for managing security groups, network interfaces, etc.
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeInternetGateways",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:CreateTags",
      "ec2:DescribeAvailabilityZones",

      # IAM permissions for assuming the role (via Web Identity)
      "sts:AssumeRoleWithWebIdentity",

      # Route 53 permissions for managing DNS records (if you're using Route 53)
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",

      # Auto Scaling permissions (if needed)
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:AttachInstances",
      "autoscaling:DetachInstances",

      # CloudWatch permissions for logging and monitoring
      "cloudwatch:PutMetricData",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetDashboard",

      # CloudFormation permissions for handling resource stacks
      "cloudformation:DescribeStacks",
      "cloudformation:DescribeStackResources",

      # wafv2 and waf-regional permissions
      "wafv2:*",
      "waf-regional:*",
    ]
    resources = ["*"]
  }

  # Additional permissions to manage ELB resource configurations
  statement {
    actions = [
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteTargetGroup"
    ]
    resources = ["arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/*"]
  }

  # Allowing access to the account's resources (e.g., ACM, ELB) across the region
  statement {
    actions = [
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = ["arn:aws:elasticloadbalancing:${var.region}:${data.aws_caller_identity.current.account_id}:targetgroup/*"]
  }
}

resource "aws_iam_role" "alb_controller_role" {
  name = "alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:block-xplorer:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "alb_controller_policy" {
  name   = "alb-controller-policy"
  policy = data.aws_iam_policy_document.alb_controller_policy.json
}

resource "aws_iam_role_policy_attachment" "alb_controller_policy_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

resource "kubernetes_service_account" "alb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = var.k8s_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
    }
  }
}

# EKS plugin not supported in 1.30 so using Helm to deploy
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = var.k8s_namespace
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.3"

  values = [
    yamlencode({
      clusterName = module.eks.cluster_name
      region      = var.region
      vpcId       = module.vpc.vpc_id
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.alb_controller_sa.metadata[0].name
      }
    })
  ]
}
