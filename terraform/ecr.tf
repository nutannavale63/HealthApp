# ECR Repositories for BBHealthApp
resource "aws_ecr_repository" "bbhealthapp_repos" {
  for_each = toset(var.ecr_repository_names)

  name                 = each.value
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = each.value
    }
  )
}

# ECR Lifecycle Policy to clean up old images
resource "aws_ecr_lifecycle_policy" "bbhealthapp_lifecycle_policy" {
  for_each = aws_ecr_repository.bbhealthapp_repos

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus = "untagged"
          countType = "sinceImagePushed"
          countUnit = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy to allow EKS nodes to pull images
data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid    = "AllowEKSNodesToPullImages"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
  }
}

resource "aws_ecr_repository_policy" "bbhealthapp_repo_policy" {
  for_each = aws_ecr_repository.bbhealthapp_repos

  repository = each.value.name
  policy     = data.aws_iam_policy_document.ecr_policy.json
}
