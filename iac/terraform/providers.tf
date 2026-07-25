# =============================================================================
# Terraform & Provider Configuration
# =============================================================================
# We pin both the Terraform CLI version and AWS provider version to ensure
# reproducible, production-safe deployments. The AWS provider is configured
# for the ap-southeast-1 (Singapore) region.
# =============================================================================

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # (Optional) Remote backend — uncomment and configure for team collaboration:
  # backend "s3" {
  #   bucket = "mycompany-terraform-state"
  #   key    = "devops-platform/terraform.tfstate"
  #   region = "ap-southeast-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Cloud-Native-DevOps-Platform"
      ManagedBy   = "Terraform"
    }
  }
}
