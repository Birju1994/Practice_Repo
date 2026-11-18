# ==============================================================================
# Terraform & Provider Requirements
# ==============================================================================
# In a production environment, always pin provider versions using pessimistic 
# version constraints (~>) to prevent unexpected breaking changes during CI/CD runs.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # In production, configure an S3 remote backend with DynamoDB state locking:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "eks/prod/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-lock-table"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  # Default tags applied to all AWS resources created by this Terraform workspace
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
