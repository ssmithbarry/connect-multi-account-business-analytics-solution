# Pearson Specific Deployment Configuration
# This file contains the actual Pearson account IDs and Connect instance information

aws_region    = "us-east-1"
project_name  = "connect-analytics"

# Update with your actual QuickSight user ARN
quicksight_user_arn = "arn:aws:quicksight:us-east-1:123456789012:user/default/your-username"

# Connect Data Lake database (actual Pearson database name)
connect_database_name = "connectanalyticsblog"

# Pearson Connect account configurations
# AWS Account IDs: Test=124355666805, Production=816069143691, Development=711387125221
account_configurations = {
  production = {
    account_id      = "816069143691"  # Pearson Production Connect account
    cost_per_minute = 0.025
    environment     = "prod"
  }
  development = {
    account_id      = "711387125221"  # Pearson Development Connect account
    cost_per_minute = 0.020
    environment     = "dev"
  }
  test = {
    account_id      = "124355666805"  # Pearson Test Connect account
    cost_per_minute = 0.015
    environment     = "test"
  }
}

tags = {
  Project     = "Pearson Connect Analytics"
  Environment = "production"
  Owner       = "AWS SA Team"
  Customer    = "Pearson"
  Purpose     = "Multi-account Connect cost analysis"
}