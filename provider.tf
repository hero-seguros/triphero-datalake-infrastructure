terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"
    }
  }

  backend "s3" {
    bucket         = "triphero-datalake-terraform-state-591698664739"
    key            = "production/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "triphero-datalake-terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "triphero-datalake-infrastructure"
    }
  }
}

# Provider for us-east-2 (MSK/EKS region)
provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "triphero-datalake-infrastructure"
    }
  }
}

# Provider for sa-east-1 (RDS region)
provider "aws" {
  alias  = "sa_east_1"
  region = "sa-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "triphero-datalake-infrastructure"
    }
  }
}
