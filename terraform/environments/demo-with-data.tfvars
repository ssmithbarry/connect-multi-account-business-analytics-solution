# Demo Environment Configuration with Demo Data Enabled
# This configuration enables the demo dataset for visualization

aws_region    = "us-east-1"
project_name  = "connect-analytics"

# Update with your actual QuickSight user ARN
quicksight_user_arn = "arn:aws:quicksight:us-east-1:123456789012:user/default/your-username"

# Connect Data Lake database (actual Pearson database name)
connect_database_name = "connectanalyticsblog"

# Enable demo data for visualization
enable_demo_data = true

# Account configurations with actual account IDs and cost rates
account_configurations = {
  production = {
    account_id      = "111111111111"  # Replace with actual production account ID
    cost_per_minute = 0.025
    environment     = "prod"
  }
  development = {
    account_id      = "222222222222"  # Replace with actual development account ID
    cost_per_minute = 0.020
    environment     = "dev"
  }
  test = {
    account_id      = "333333333333"  # Replace with actual test account ID
    cost_per_minute = 0.015
    environment     = "test"
  }
}

tags = {
  Project     = "Pearson Connect Analytics"
  Environment = "demo-with-data"
  Owner       = "AWS SA Team"
  Purpose     = "Multi-account Connect cost analysis with demo data"
  DataType    = "Demo"
}