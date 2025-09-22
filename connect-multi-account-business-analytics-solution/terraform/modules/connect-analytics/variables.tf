variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "quicksight_user_arn" {
  description = "QuickSight user ARN for dashboard permissions"
  type        = string
}

variable "connect_database_name" {
  description = "Connect Data Lake database name"
  type        = string
}

variable "account_configurations" {
  description = "Configuration for each Connect account"
  type = map(object({
    account_id      = string
    cost_per_minute = number
    environment     = string
  }))
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "enable_demo_data" {
  description = "Enable demo dataset for visualization when real Connect data isn't available"
  type        = bool
  default     = false
}