terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Connect Analytics Module
module "connect_analytics" {
  source = "./modules/connect-analytics"

  project_name           = var.project_name
  quicksight_user_arn   = var.quicksight_user_arn
  connect_database_name = var.connect_database_name
  account_configurations = var.account_configurations
  enable_demo_data      = var.enable_demo_data
  
  tags = var.tags
}