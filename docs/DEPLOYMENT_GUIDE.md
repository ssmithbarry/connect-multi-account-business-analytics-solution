# Connect Analytics Deployment Guide

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** installed (>= 1.0)
3. **Python 3.7+** for demo data generation
4. **Amazon Connect Data Lake** enabled in source accounts
5. **QuickSight Enterprise** edition activated

## Quick Start

### CloudShell Deployment (Recommended for Demos)
```bash
git clone https://github.com/your-repo/connect-multi-account-business-analytics-solution.git
cd connect-multi-account-business-analytics-solution
pip install -r requirements.txt
cd terraform
terraform init
terraform apply -var-file="environments/demo-with-data.tfvars"
```

### Local Deployment
```bash
git clone https://github.com/your-repo/connect-multi-account-business-analytics-solution.git
cd connect-multi-account-business-analytics-solution
pip install -r requirements.txt
cd terraform
terraform init
terraform apply -var-file="environments/demo.tfvars"
```

## Configuration

### Basic Configuration (demo.tfvars)
```hcl
aws_region = "us-east-1"
connect_database_name = "connect_data_lake"
quicksight_user_arn = "arn:aws:quicksight:us-east-1:123456789012:user/default/username"
```

### Multi-Account Configuration
```hcl
aws_region = "us-east-1"
connect_database_name = "connectanalyticsblog"  # Instance-specific name
quicksight_user_arn = "arn:aws:quicksight:us-east-1:816069143691:user/default/username"

# Account mappings for cost analysis
production_account_id = "816069143691"
development_account_id = "711387125221"
test_account_id = "124355666805"
```

## Deployment Steps

### 1. Enable Connect Data Lake
In each Connect account:
1. Go to Connect console → Instance → Data streaming
2. Enable Data Lake
3. For cross-account: specify target analytics account ID
4. Wait 15-30 minutes for setup

### 2. Configure Variables
Create or update your `.tfvars` file:
```hcl
# Required
aws_region = "us-east-1"
connect_database_name = "your_database_name"
quicksight_user_arn = "your_quicksight_user_arn"

# Optional - for demo data
enable_demo_dataset = true
demo_data_s3_bucket = "your-demo-bucket"
```

### 3. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply -var-file="environments/your-config.tfvars"
```

### 4. Verify Deployment
1. Check QuickSight dashboard creation
2. Verify data source connectivity
3. Test dashboard visualizations

## Demo Data Generation

If your Connect instances have no call data:
```bash
cd scripts
python generate-demo-data.py
```

This creates 4,500+ realistic contact records for visualization.

## Cleanup

```bash
terraform destroy -var-file="environments/your-config.tfvars"
```

## Next Steps

1. Customize dashboard visualizations
2. Add additional data sources
3. Configure automated data refresh
4. Set up alerting and monitoring