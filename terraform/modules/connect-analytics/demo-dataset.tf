# Optional demo dataset for visualization when real Connect data isn't available
# This creates a separate dataset pointing to demo data without affecting the main dataset

resource "aws_quicksight_data_set" "demo_cost_analysis" {
  count = var.enable_demo_data ? 1 : 0
  
  data_set_id = "${var.project_name}-demo-cost-analysis-dataset"
  name        = "${var.project_name} Demo Cost Analysis"
  import_mode = "SPICE"

  physical_table_map {
    physical_table_id = "demo-cost-analysis-table"
    
    relational_table {
      data_source_arn = aws_quicksight_data_source.connect_analytics.arn
      catalog         = "AwsDataCatalog"
      schema          = var.connect_database_name
      name            = "demo_contact_records"
      
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
    logical_table_id = "demo-cost-analysis-logical"
    alias           = "Demo Multi-Account Cost Analysis"
    
    source {
      physical_table_id = "demo-cost-analysis-table"
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "account_name"
          column_id   = "demo-account-name-calc"
          expression  = local.account_name_expression
        }
      }
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "cost_per_minute"
          column_id   = "demo-cost-per-minute-calc"
          expression  = local.cost_per_minute_expression
        }
      }
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "call_duration_minutes"
          column_id   = "demo-duration-calc"
          expression  = "dateDiff(disconnect_timestamp, initiation_timestamp) / 60000.0"
        }
      }
    }

    data_transforms {
      create_columns_operation {
        columns {
          column_name = "total_cost"
          column_id   = "demo-total-cost-calc"
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

  tags = merge(var.tags, {
    DataType = "Demo"
    Purpose  = "Visualization with sample data"
  })
}