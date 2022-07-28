terraform {
  
    backend "s3" {
    bucket  = "Example-dev-terraform-state"
    key     = "dev"
    region  = "us-east-1"
    profile = "ExampleNewDevProfile"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.22"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "ExampleNewDevProfile"
}