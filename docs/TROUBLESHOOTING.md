# Troubleshooting Guide

## Common Issues

### Database Not Found
**Error**: `Database 'connect_data_lake' not found`

**Cause**: Connect Data Lake not enabled or still setting up

**Solution**:
```bash
# Check if database exists
aws glue get-databases --query "DatabaseList[?contains(Name, 'connect')]"

# If no databases found, enable Connect Data Lake in Connect console
# Wait 15-30 minutes for database creation
```

### Empty Database (No Call Data)
**Symptoms**: Dashboard shows no data, tables are empty

**Solutions**:

**Option 1: Generate Demo Data**
```bash
cd scripts
python generate-demo-data.py
terraform apply -var-file="environments/demo-with-data.tfvars"
```

**Option 2: Generate Real Call Data**
1. Make test calls in Connect instances
2. Wait 30-60 minutes for data processing
3. Verify data appears in Athena

### Cross-Account Data Not Appearing
**Expected Timing**: 1-4 hours for cross-account sharing, up to 24 hours for full sync

**Verification**:
```bash
# Check for shared databases
aws glue get-databases --query "DatabaseList[?contains(Name, 'connect')]"

# Verify Lake Formation permissions
aws lakeformation list-permissions --principal "arn:aws:iam::ACCOUNT_ID:root"
```

### QuickSight Permission Errors
**Error**: `User does not have permissions to access data source`

**Solution**:
1. Verify QuickSight user ARN is correct
2. Check QuickSight Enterprise edition is enabled
3. Ensure user has appropriate QuickSight permissions

### Terraform State Issues
**Error**: `Resource already exists` or state conflicts

**Solutions**:
```bash
# Import existing resources
terraform import aws_quicksight_data_source.connect existing_id

# Or start fresh
terraform destroy
terraform apply
```

### Instance-Specific Database Names
**Issue**: Connect creates instance-specific database names, not generic `connect_data_lake`

**Solution**:
```bash
# Find actual database name
aws glue get-databases --query "DatabaseList[?contains(Name, 'connect')].Name"

# Update terraform.tfvars with actual name
connect_database_name = "connectanalyticsblog"  # Use actual name
```

## Verification Commands

### Check Connect Data Lake Status
```bash
# List Connect instances
aws connect list-instances

# Check Data Lake configuration
aws connect describe-instance-storage-config --instance-id INSTANCE_ID --resource-type CONTACT_TRACE_RECORDS
```

### Verify Database and Tables
```bash
# List Connect databases
aws glue get-databases --query "DatabaseList[?contains(Name, 'connect')]"

# Check tables in database
aws glue get-tables --database-name DATABASE_NAME

# Test Athena query
aws athena start-query-execution \
  --query-string "SELECT COUNT(*) FROM DATABASE_NAME.contact_records" \
  --result-configuration OutputLocation=s3://your-athena-results-bucket/
```

### QuickSight Verification
```bash
# List QuickSight data sources
aws quicksight list-data-sources --aws-account-id ACCOUNT_ID

# List QuickSight datasets
aws quicksight list-data-sets --aws-account-id ACCOUNT_ID

# List QuickSight dashboards
aws quicksight list-dashboards --aws-account-id ACCOUNT_ID
```

## Recovery Procedures

### Complete Reset
```bash
# Destroy all resources
terraform destroy -var-file="environments/your-config.tfvars"

# Clean state
rm -rf .terraform terraform.tfstate*

# Redeploy
terraform init
terraform apply -var-file="environments/your-config.tfvars"
```

### Partial Recovery
```bash
# Refresh state
terraform refresh -var-file="environments/your-config.tfvars"

# Plan to see differences
terraform plan -var-file="environments/your-config.tfvars"

# Apply only specific resources
terraform apply -target=module.connect_analytics.aws_quicksight_dashboard.main
```

## Getting Help

1. Check AWS service health status
2. Review CloudTrail logs for API errors
3. Check Terraform logs with `TF_LOG=DEBUG`
4. Verify IAM permissions for all services
5. Test connectivity with AWS CLI commands