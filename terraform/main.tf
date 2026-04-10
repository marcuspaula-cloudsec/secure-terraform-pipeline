terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "security-terraform-state"
    key            = "pipeline/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  # Assume role via OIDC — no static credentials
  assume_role {
    role_arn = var.deploy_role_arn
  }

  default_tags {
    tags = {
      Project     = "secure-terraform-pipeline"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
