# Create an ECR repository named block-xplorer
resource "aws_ecr_repository" "block_xplorer" {
  name                 = "block-xplorer"
  image_tag_mutability = "MUTABLE" # Allow image tags to be mutable (optional)
}

resource "aws_ecr_lifecycle_policy" "block_xplorer_policy" {
  repository = aws_ecr_repository.block_xplorer.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain only the 30 most recent images"
        selection    = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action       = {
          type = "expire"
        }
      }
    ]
  })
}
