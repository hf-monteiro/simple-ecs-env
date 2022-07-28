locals {
 services = ["csv-service", "ecommerce", "service02", "imageservice", "service02", "online", "payments", "paymentservice", "service03service", "example"]   
}

resource "aws_ecr_repository" "dev-repos" {
    for_each = toset(local.services)
    name = "Example-${each.value}-dev"
}