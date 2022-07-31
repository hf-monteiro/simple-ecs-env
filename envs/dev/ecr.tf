# ECR creation with for_each
locals {
 services = ["example01", "example02", "example03"]   
}

resource "aws_ecr_repository" "dev-repos" {
    for_each = toset(local.services)
    name = "Example-${each.value}-dev"
}