locals {
  cluster_name = "${var.eks_cluster_name}-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.29.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    primary = {
      name = "primary-node-group"

      ami_type = "AL2_x86_64"

      instance_types = [var.primary_node_group_instance_type]

      min_size     = 1
      max_size     = var.primary_node_group_count
      desired_size = var.primary_node_group_count
    }
  }
}

resource "kubernetes_namespace" "block_xplorer" {
  metadata {
    name = var.k8s_namespace
  }
}

resource "kubernetes_secret" "infura_api_key" {
  metadata {
    name      = "infura-api-key"
    namespace = kubernetes_namespace.block_xplorer.metadata[0].name
  }

  data = {
    INFURA_API_KEY = var.infura_api_key
  }

  type = "python_environment_secret"
}

# test secret to test ci/cd
resource "aws_secretsmanager_secret" "my_secret" {
  name        = "my_secret_fdafjke"
  description = "This is a simple AWS secret"
}

resource "aws_secretsmanager_secret_version" "my_secret_version" {
  secret_id     = aws_secretsmanager_secret.my_secret.id
  secret_string = jsonencode({
    username = "my-username"
    password = "my-passwordtest3"
  })
}
