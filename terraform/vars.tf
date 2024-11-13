variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  sensitive   = true
}

variable "infura_api_key" {
  description = "Infura API key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster"
  type        = string
  default     = "block-xplorer"
}

variable "primary_node_group_instance_type" {
  description = "The instance type for the primary node pool"
  type        = string
  default     = "t3.small"
}

variable "primary_node_group_count" {
  description = "The number of nodes in the primary node pool"
  type        = number
  default     = 2
}

variable "domain_name" {
  description = "A valid DNS name for the application"
  type        = string
  default     = "klehmerdev.com"
}

variable "region" {
  description = "AWS region where application is deployed"
  type        = string
  default     = "us-east-2"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace where application is deployed"
  type        = string
  default     = "block-xplorer"
}

variable "github_token" {
  description = "Github token"
  type        = string
  sensitive   = true
}
