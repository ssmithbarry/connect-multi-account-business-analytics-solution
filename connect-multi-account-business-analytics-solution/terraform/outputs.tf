output "quicksight_dashboard_url" {
  description = "URL to access the QuickSight dashboard"
  value       = module.connect_analytics.dashboard_url
}

output "quicksight_data_source_arn" {
  description = "ARN of the QuickSight data source"
  value       = module.connect_analytics.data_source_arn
}

output "athena_views_created" {
  description = "List of Athena views created for cost analysis"
  value       = module.connect_analytics.athena_views
}

output "deployment_instructions" {
  description = "Next steps for completing the setup"
  value = <<-EOT
    
    🎯 Deployment Complete! Next Steps:
    
    1. Enable Connect Data Lake in each account:
       - Production: ${var.account_configurations.production.account_id}
       - Development: ${var.account_configurations.development.account_id}  
       - Test: ${var.account_configurations.test.account_id}
    
    2. Configure Lake Formation cross-account sharing
    
    3. Access your dashboard: ${module.connect_analytics.dashboard_url}
    
    4. Run the data generator script to populate demo data:
       python scripts/generate-dummy-data.py
    
    📊 Dashboard Features:
    - Multi-account cost analysis
    - Agent performance metrics
    - Executive summary views
    - Real-time contact analytics
    
  EOT
}