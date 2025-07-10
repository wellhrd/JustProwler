module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.1"

  for_each        = toset(var.ecr_repositories)
  repository_name = each.key

  repository_type                 = "private"
  repository_image_tag_mutability = var.repository_image_tag_mutability
  repository_image_scan_on_push   = true 
  repository_force_delete         = true
  create_lifecycle_policy         = true

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep the 4/6 docker images for prowler",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 4
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}