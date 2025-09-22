variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "connect-analytics"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "quicksight_user_arn" {
  description = "QuickSight user ARN for dashboard permissions"
  type        = string
  
  validation {
    condition     = can(regex("^arn:aws:quicksight:[a-z0-9-]+:[0-9]+:user/default/[a-zA-Z0-9._-]+$", var.quicksight_user_arn))
    error_message = "QuickSight user ARN must be in the format: arn:aws:quicksight:region:account:user/default/username"
  }
}

variable "connect_database_name" {
  description = "Connect Data Lake database name (created by Connect service)"
  type        = string
  default     = "connect_data_lake"
}

variable "account_configurations" {
  description = "Configuration for each Connect account"
  type = map(object({
    account_id      = string
    cost_per_minute = number
    environment     = string
  }))
  default = {
    production = {
      account_id      = "111111111111"
      cost_per_minute = 0.025
      environment     = "prod"
    }
    development = {
      account_id      = "222222222222"
      cost_per_minute = 0.020
      environment     = "dev"
    }
    test = {
      account_id      = "333333333333"
      cost_per_minute = 0.015
      environment     = "test"
    }
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Connect Analytics"
    Environment = "demo"
    Owner       = "AWS SA"
  }
}

variable "enable_demo_data" {
  description = "Enable demo dataset for visualization when real Connect data isn't available"
  type        = bool
  default     = false
}