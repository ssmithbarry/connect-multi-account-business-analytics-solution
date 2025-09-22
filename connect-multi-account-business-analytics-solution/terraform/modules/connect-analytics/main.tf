terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# QuickSight Data Source (connects to Connect Data Lake via Athena)
resource "aws_quicksight_data_source" "connect_analytics" {
  data_source_id = "${var.project_name}-athena-datasource"
  name           = "${var.project_name} Multi-Account Analytics"
  type           = "ATHENA"

  parameters {
    athena {
      work_group = "primary"
    }
  }

  permission {
    principal = var.quicksight_user_arn
    actions = [
      "quicksight:UpdateDataSourcePermissions",
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource"
    ]
  }

  ssl_properties {
    disable_ssl = false
  }

  tags = var.tags
}

# Athena View for Multi-Account Cost Analysis
resource "aws_athena_named_query" "cost_analysis_view" {
  name        = "${var.project_name}_cost_analysis_view"
  database    = var.connect_database_name
  description = "Multi-account Connect cost analysis view"
  
  query = templatefile("${path.module}/sql/cost_analysis_view.sql", {
    database_name = var.connect_database_name
    account_configs = var.account_configurations
  })
}

# Athena View for Executive Summary
resource "aws_athena_named_query" "executive_summary_view" {
  name        = "${var.project_name}_executive_summary_view"
  database    = var.connect_database_name
  description = "Executive summary for multi-account Connect analytics"
  
  query = templatefile("${path.module}/sql/executive_summary_view.sql", {
    database_name = var.connect_database_name
  })
}

# QuickSight Dataset for Cost Analysis
resource "aws_quicksight_data_set" "cost_analysis" {
  data_set_id = "${var.project_name}-cost-analysis-dataset"
  name        = "${var.project_name} Multi-Account Cost Analysis"
  import_mode = "SPICE"

  physical_table_map {
    physical_table_id = "cost-analysis-table"
    
    relational_table {
      data_source_arn = aws_quicksight_data_source.connect_analytics.arn
      catalog         = "AwsDataCatalog"
      schema          = var.connect_database_name
      name            = "contact_records"
      
      input_columns {
        name = "contact_id"
        type = "STRING"
      }
      input_columns {
        name = "aws_account_id"
        type = "STRING"
      }
      input_columns {
        name = "initiation_timestamp"
        type = "DATETIME"
      }
      input_columns {
        name = "disconnect_timestamp"
        type = "DATETIME"
      }
      input_columns {
        name = "channel"
        type = "STRING"
      }
      input_columns {
        name = "queue_name"
        type = "STRING"
      }
      input_columns {
        name = "agent_username"
        type = "STRING"
      }
      input_columns {
        name = "disconnect_reason"
        type = "STRING"
      }
    }
  }

  logical_table_map {
    logical_table_id = "cost-analysis-logical"
    alias           = "Multi-Account Cost Analysis"
    
    source {
      physical_table_id = "cost-analysis-table"
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "account_name"
          column_id   = "account-name-calc"
          expression  = local.account_name_expression
        }
      }
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "cost_per_minute"
          column_id   = "cost-per-minute-calc"
          expression  = local.cost_per_minute_expression
        }
      }
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "call_duration_minutes"
          column_id   = "duration-calc"
          expression  = "dateDiff(disconnect_timestamp, initiation_timestamp) / 60000.0"
        }
      }
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "total_cost"
          column_id   = "total-cost-calc"
          expression  = "call_duration_minutes * cost_per_minute"
        }
      }
    }
  }

  permission {
    principal = var.quicksight_user_arn
    actions = [
      "quicksight:UpdateDataSetPermissions",
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion"
    ]
  }

  tags = var.tags
}

# QuickSight Dashboard
resource "aws_quicksight_dashboard" "connect_analytics" {
  dashboard_id = "${var.project_name}-analytics-dashboard"
  name         = "${var.project_name} Multi-Account Analytics Dashboard"

  definition {
    data_set_identifiers_declarations {
      data_set_arn    = aws_quicksight_data_set.cost_analysis.arn
      identifier      = "cost-analysis"
    }

    # Simple sheet with key visuals
    sheets {
      sheet_id = "overview-sheet"
      name     = "Multi-Account Overview"
      
      visuals {
        bar_chart_visual {
          visual_id = "cost-by-account"
          title {
            visibility = "VISIBLE"
            format_text {
              rich_text = "<visual-title>Cost by Account (Last 30 Days)</visual-title>"
            }
          }
          
          chart_configuration {
            field_wells {
              bar_chart_aggregated_field_wells {
                category {
                  categorical_dimension_field {
                    field_id = "account-category"
                    column {
                      column_name         = "account_name"
                      data_set_identifier = "cost-analysis"
                    }
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "cost-value"
                    column {
                      column_name         = "total_cost"
                      data_set_identifier = "cost-analysis"
                    }
                    aggregation_function {
                      simple_numerical_aggregation = "SUM"
                    }
                  }
                }
              }
            }
            orientation = "VERTICAL"
            data_labels {
              visibility = "VISIBLE"
            }
          }
        }
      }

      visuals {
        line_chart_visual {
          visual_id = "cost-trend"
          title {
            visibility = "VISIBLE"
            format_text {
              rich_text = "<visual-title>Daily Cost Trend</visual-title>"
            }
          }
          
          chart_configuration {
            field_wells {
              line_chart_aggregated_field_wells {
                category {
                  date_dimension_field {
                    field_id = "date-category"
                    column {
                      column_name         = "initiation_timestamp"
                      data_set_identifier = "cost-analysis"
                    }
                    date_granularity = "DAY"
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "daily-cost"
                    column {
                      column_name         = "total_cost"
                      data_set_identifier = "cost-analysis"
                    }
                    aggregation_function {
                      simple_numerical_aggregation = "SUM"
                    }
                  }
                }
                colors {
                  categorical_dimension_field {
                    field_id = "account-color"
                    column {
                      column_name         = "account_name"
                      data_set_identifier = "cost-analysis"
                    }
                  }
                }
              }
            }
            type = "LINE"
          }
        }
      }

      visuals {
        table_visual {
          visual_id = "agent-performance"
          title {
            visibility = "VISIBLE"
            format_text {
              rich_text = "<visual-title>Top Agents by Cost</visual-title>"
            }
          }
          
          chart_configuration {
            field_wells {
              table_aggregated_field_wells {
                group_by {
                  categorical_dimension_field {
                    field_id = "agent-name"
                    column {
                      column_name         = "agent_username"
                      data_set_identifier = "cost-analysis"
                    }
                  }
                }
                group_by {
                  categorical_dimension_field {
                    field_id = "account-name"
                    column {
                      column_name         = "account_name"
                      data_set_identifier = "cost-analysis"
                    }
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "agent-calls"
                    column {
                      column_name         = "contact_id"
                      data_set_identifier = "cost-analysis"
                    }
                    aggregation_function {
                      simple_numerical_aggregation = "COUNT"
                    }
                  }
                }
                values {
                  numerical_measure_field {
                    field_id = "agent-cost"
                    column {
                      column_name         = "total_cost"
                      data_set_identifier = "cost-analysis"
                    }
                    aggregation_function {
                      simple_numerical_aggregation = "SUM"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  dashboard_publish_options {
    ad_hoc_filtering_option {
      availability_status = "ENABLED"
    }
    export_to_csv_option {
      availability_status = "ENABLED"
    }
    sheet_controls_option {
      visibility_state = "EXPANDED"
    }
  }

  permission {
    principal = var.quicksight_user_arn
    actions = [
      "quicksight:DescribeDashboard",
      "quicksight:ListDashboardVersions",
      "quicksight:UpdateDashboardPermissions",
      "quicksight:QueryDashboard",
      "quicksight:UpdateDashboard",
      "quicksight:DeleteDashboard",
      "quicksight:DescribeDashboardPermissions",
      "quicksight:ExportDashboard"
    ]
  }

  tags = var.tags
}

# Local values for calculated fields
locals {
  # Create account name mapping expression
  account_name_expression = join("", [
    "ifelse(",
    join(", ", [
      for name, config in var.account_configurations :
      "aws_account_id = '${config.account_id}', '${name}'"
    ]),
    ", 'Unknown')"
  ])

  # Create cost per minute mapping expression  
  cost_per_minute_expression = join("", [
    "ifelse(",
    join(", ", [
      for name, config in var.account_configurations :
      "aws_account_id = '${config.account_id}', ${config.cost_per_minute}"
    ]),
    ", 0.02)"
  ])
}