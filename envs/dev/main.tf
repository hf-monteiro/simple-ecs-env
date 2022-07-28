//This file will need to be cleaned up to not rely on a hardcoded profile name. 
//The whole process will need to be different for CI/CD integration. This is quick and dirty to get
//things up and running.
terraform {
  
    backend "s3" {
    bucket  = "Example-dev-terraform-state"
    key     = "dev"
    region  = "us-east-1"
    profile = "ExampleNewDev"
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
  profile = "ExampleNewDev"
}