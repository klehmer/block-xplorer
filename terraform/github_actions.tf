locals {
  block_xplorer_repo = "block-xplorer"
}

resource "github_actions_secret" "aws_access_key" {
  repository      = local.block_xplorer_repo
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.aws_access_key_id
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = local.block_xplorer_repo
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.aws_secret_access_key
}

resource "github_actions_variable" "aws_region" {
  repository    = local.block_xplorer_repo
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

resource "github_actions_variable" "ecr_repository_uri" {
  repository    = local.block_xplorer_repo
  variable_name = "ECR_REPOSITORY_URI"
  value         = aws_ecr_repository.block_xplorer.repository_url
}

resource "github_actions_variable" "ecr_repository_name" {
  repository    = local.block_xplorer_repo
  variable_name = "ECR_REPOSITORY"
  value         = aws_ecr_repository.block_xplorer.name
}

resource "github_actions_variable" "eks_cluster_name" {
  repository    = local.block_xplorer_repo
  variable_name = "CLUSTER_NAME"
  value         = module.eks.cluster_name
}

resource "github_actions_variable" "k8s_namespace" {
  repository    = local.block_xplorer_repo
  variable_name = "K8S_NAMESPACE"
  value         = kubernetes_namespace.block_xplorer.metadata[0].name
}

resource "github_actions_variable" "terraform_state_bucket" {
  repository    = local.block_xplorer_repo
  variable_name = "TF_STATE_BUCKET"
  value = "block-xplorer-tf-state"
}

resource "github_actions_secret" "infura_api_key" {
  repository    = local.block_xplorer_repo
  secret_name = "INFURA_API_KEY"
  plaintext_value = var.infura_api_key
}

resource "github_actions_secret" "github_token" {
  repository    = local.block_xplorer_repo
  secret_name = "GH_TOKEN"
  plaintext_value = var.github_token
}
