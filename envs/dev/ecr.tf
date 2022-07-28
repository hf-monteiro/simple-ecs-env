locals {
 services = ["csv-service", "ecommerce", "ecommerce-service", "imageservice", "integrations", "online", "payments", "paymentservice", "reportingservice", "shipping"]   
}

resource "aws_ecr_repository" "dev-repos" {
    for_each = toset(local.services)
    name = "Example-${each.value}-dev"
}