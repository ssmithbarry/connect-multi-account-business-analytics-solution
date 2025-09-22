output "dashboard_url" {
  description = "URL to access the QuickSight dashboard"
  value       = "https://${data.aws_region.current.name}.quicksight.aws.amazon.com/sn/dashboards/${aws_quicksight_dashboard.connect_analytics.dashboard_id}"
}

output "data_source_arn" {
  description = "ARN of the QuickSight data source"
  value       = aws_quicksight_data_source.connect_analytics.arn
}

output "dataset_arn" {
  description = "ARN of the QuickSight dataset"
  value       = aws_quicksight_data_set.cost_analysis.arn
}

output "athena_views" {
  description = "List of Athena views created"
  value = [
    aws_athena_named_query.cost_analysis_view.name,
    aws_athena_named_query.executive_summary_view.name
  ]
}