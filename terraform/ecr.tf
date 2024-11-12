# Create an ECR repository named block-xplorer
resource "aws_ecr_repository" "block_xplorer" {
  name                 = "block-xplorer"
  image_tag_mutability = "MUTABLE" # Allow image tags to be mutable (optional)
}

# Output the repository URL
output "ecr_repository_url" {
  value       = aws_ecr_repository.block_xplorer.repository_url
  description = "URL of the ECR repository for block-xplorer"
}
