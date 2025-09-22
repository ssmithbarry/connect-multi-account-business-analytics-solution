# Pearson Connect Analytics - Deployment Notes

## 📋 Pearson Account Information

### AWS Account IDs with Connect Instances
- **Test**: `124355666805`
- **Production/Analytics**: `816069143691` (Connect + QuickSight/Athena)
- **Development**: `711387125221`

### Connect Instance IDs
> Note: Connect instance IDs would be helpful for documentation but aren't required for Terraform deployment since we use Connect Data Lake which aggregates at account level.

## 🚀 Pearson-Specific Deployment

### Use Pearson Configuration
```bash
cd terraform
terraform apply -var-file="environments/pearson-deployment.tfvars"
```

### Configuration File
The Pearson-specific configuration is in:
- `terraform/environments/pearson-deployment.tfvars`

This contains the actual Pearson account IDs while keeping the template files generic for reuse.

## 📊 Expected Data Sources

### Account Mapping
- **Production/Analytics (816069143691)**: $0.025/minute (Connect + QuickSight)
- **Development (711387125221)**: $0.020/minute  
- **Test (124355666805)**: $0.015/minute

### Connect Data Lake Requirements
**IMPORTANT**: Connect Data Lake with data sharing handles cross-account access automatically

Each account needs:
1. Connect Data Lake enabled with **data sharing to analytics account (816069143691)**
2. All Connect accounts share data to the same target account
3. No manual Lake Formation permissions required

**How Connect Data Lake Sharing Works:**
- When enabling Data Lake, specify target account ID (816069143691)
- Connect automatically creates shared databases in the target account
- Cross-account Lake Formation permissions are handled by Connect service
- All shared data appears in analytics account's `connect_data_lake` database

## 🔧 Next Steps for Pearson

1. **Enable Connect Data Lake** in each account:
   
   **Step 1.1: Check if Connect Data Lake is enabled**
   ```bash
   # In each Connect account, check if database exists
   aws glue get-database --name connect_data_lake
   ```
   
   **Step 1.2: Enable Connect Data Lake (if not enabled)**
   
   **Via AWS Console:**
   - Account 816069143691 (Production/Analytics)
   - Account 711387125221 (Development) 
   - Account 124355666805 (Test)
   
   **For each account:**
   1. Go to Amazon Connect console
   2. Select your Connect instance
   3. Navigate to "Data streaming" in left menu
   4. Under "Data Lake", click "Enable"
   5. Wait 15-30 minutes for database creation
   6. Verify: `aws glue get-database --name connect_data_lake`
   
   **Via CLI (if supported):**
   ```bash
   # List Connect instances
   aws connect list-instances
   
   # Enable data streaming (replace INSTANCE_ID)
   aws connect associate-instance-storage-config \
     --instance-id INSTANCE_ID \
     --resource-type CONTACT_TRACE_RECORDS \
     --storage-config StorageType=KINESIS_DATA_FIREHOSE
   ```

2. **Configure Connect Data Lake with Cross-Account Sharing**

   **How Connect Data Lake Sharing Works:**
   - Each Connect account shares data to analytics account (816069143691)
   - Connect service handles Lake Formation permissions automatically
   - All shared data appears in single `connect_data_lake` database in analytics account
   - No manual Lake Formation grants required

   **Step 2.1: Enable Data Lake with Sharing in Development (711387125221)**
   1. Go to Amazon Connect console
   2. Select Connect instance
   3. Navigate to "Data streaming" → "Data Lake"
   4. Click "Enable"
   5. **Specify target account**: `816069143691` (Production/Analytics)
   6. Wait for setup completion
   
   **Step 2.2: Enable Data Lake with Sharing in Test (124355666805)**
   1. Go to Amazon Connect console
   2. Select Connect instance
   3. Navigate to "Data streaming" → "Data Lake"
   4. Click "Enable"
   5. **Specify target account**: `816069143691` (Production/Analytics)
   6. Wait for setup completion
   
   **Step 2.3: Enable Data Lake in Production/Analytics (816069143691)**
   1. Go to Amazon Connect console
   2. Select Connect instance
   3. Navigate to "Data streaming" → "Data Lake"
   4. Click "Enable"
   5. **Target account**: Same account (816069143691)
   6. Wait for setup completion
   
   **Step 2.4: Verification in Analytics Account (816069143691)**
   ```bash
   # Check for consolidated database with all account data
   aws glue get-databases --query "DatabaseList[?Name=='connect_data_lake']"
   
   # Verify tables contain data from all accounts
   aws glue get-tables --database-name connect_data_lake
   
   # Test Athena query across all accounts
   aws athena start-query-execution \
     --query-string "SELECT aws_account_id, COUNT(*) FROM connect_data_lake.contact_records GROUP BY aws_account_id" \
     --result-configuration OutputLocation=s3://aws-athena-query-results-816069143691-us-east-1/
   ```

3. **Update QuickSight user ARN** in `pearson-deployment.tfvars`

4. **Deploy**: `terraform apply -var-file="environments/pearson-deployment.tfvars"`

## 🚨 Troubleshooting

### Multiple Connect Databases Causing Confusion

**IMPORTANT**: Connect Data Lake creates **instance-specific database names**, not generic `connect_data_lake`

**Your situation:**
- `connect_database` (Sept 3) - likely from one Connect instance
- `connectanalyticsblog` (Sept 18) - likely from another Connect instance
- Missing `connect_data_lake` - this is the expected generic name but may not exist

**How to identify the correct database:**
```bash
# Check which databases have contact_records tables
for db in connect_database connectanalyticsblog; do
  echo "Checking $db:"
  aws glue get-tables --database-name $db --query "TableList[?Name=='contact_records'].Name" --output text
done

# Check for any tables with 'contact' in the name
for db in connect_database connectanalyticsblog; do
  echo "Tables in $db:"
  aws glue get-tables --database-name $db --query "TableList[].Name" --output table
done
```

**Solution:**
1. **Identify which database contains your current Connect data**
2. **Update Terraform configuration** to use the correct database name
3. **Use that database for your analytics**

**Update your `pearson-deployment.tfvars`:**
```hcl
# Change from generic name to actual database name
connect_database_name = "connect_database"  # or "connectanalyticsblog"
```

### Cross-Account Data Shares Not Appearing in Analytics Account

**This is NORMAL and expected** - Connect Data Lake cross-account sharing has significant delays:

**Expected Timing:**
- **Initial setup**: 15-30 minutes per account
- **Cross-account sharing**: 1-4 hours after setup
- **First data appearance**: 2-6 hours after first calls
- **Full synchronization**: Up to 24 hours

**Verification Steps:**
```bash
# In analytics account (816069143691), check for Connect databases
aws glue get-databases --query "DatabaseList[?contains(Name, 'connect')]"

# Check Lake Formation permissions (corrected syntax)
aws lakeformation list-permissions --principal "arn:aws:iam::816069143691:root"

# Check for specific Connect Data Lake database
aws glue get-database --name connect_data_lake 2>/dev/null || echo "connect_data_lake not found"

# Check tables in existing Connect databases
aws glue get-tables --database-name connect_database --query "TableList[].Name"
aws glue get-tables --database-name connectanalyticsblog --query "TableList[].Name"
```

**What to check while waiting:**
1. **In source accounts** (Development/Test):
   ```bash
   # Verify Data Lake is enabled and sharing is configured
   aws connect list-instances
   aws connect describe-instance-storage-config --instance-id INSTANCE_ID --resource-type CONTACT_TRACE_RECORDS
   ```

2. **In analytics account** (Production):
   ```bash
   # Check for any Lake Formation permissions (corrected syntax)
   aws lakeformation list-permissions --principal "arn:aws:iam::816069143691:root"
   
   # List all databases to see what Connect created
   aws glue get-databases --query "DatabaseList[?contains(Name, 'connect')]"
   
   # Check what's in the existing Connect databases
   aws glue get-tables --database-name connect_database
   aws glue get-tables --database-name connectanalyticsblog
   ```

### Error: "Database not found" during setup

**Cause**: Connect Data Lake not enabled in the account

**Solution**:
1. **Check if database exists:**
   ```bash
   aws glue get-database --name connect_data_lake
   ```

2. **If database doesn't exist, enable Connect Data Lake:**
   - Go to Connect console → Instance → Data streaming → Enable Data Lake
   - Wait 15-30 minutes for database creation
   - Verify setup completion

3. **Verify database creation:**
   ```bash
   # Should show connect_data_lake database
   aws glue get-databases --query "DatabaseList[?Name=='connect_data_lake']"
   
   # Should show contact_records table (may take additional time)
   aws glue get-tables --database-name connect_data_lake
   ```

### Cross-Account Sharing Taking Too Long (>24 hours)

**Possible Issues:**
1. **Incorrect target account specified** during Data Lake setup
2. **Lake Formation permissions blocked** by organizational policies
3. **Regional mismatch** - ensure all accounts in same region

**Solutions:**
```bash
# Check Data Lake configuration in source accounts
aws connect describe-instance-storage-config --instance-id INSTANCE_ID --resource-type CONTACT_TRACE_RECORDS

# Verify target account ID is correct (should be 816069143691)
# If wrong, disable and re-enable Data Lake with correct target
```

### Database Exists But Is Empty (No Call Data)

**Your Situation**: `connectanalyticsblog` database exists but tables are empty because Connect instances have no call activity.

**Immediate Solutions:**

**Option 1: Use Demo Data for Visualization**
```bash
# Generate realistic demo data
cd scripts
python generate-demo-data.py

# Update Terraform to use correct database name
cd ../terraform
# Edit pearson-deployment.tfvars:
# connect_database_name = "connectanalyticsblog"

# Deploy with demo data
terraform apply -var-file="environments/demo-with-data.tfvars"
```

**Option 2: Generate Call Data in Connect**
1. **Make test calls** in each Connect instance:
   - Production (816069143691): Make 10-20 test calls
   - Development (711387125221): Make 10-20 test calls  
   - Test (124355666805): Make 10-20 test calls
2. **Wait 30-60 minutes** for data processing
3. **Check for data**:
   ```bash
   aws athena start-query-execution \
     --query-string "SELECT COUNT(*) FROM connectanalyticsblog.contact_records" \
     --result-configuration OutputLocation=s3://aws-athena-query-results-816069143691-us-east-1/
   ```

**Recommended Approach**: Use demo data now, add real call data later

### Alternative: Use Demo Data While Waiting

**If cross-account sharing is delayed, use demo data for immediate visualization:**
```bash
cd scripts
python generate-demo-data.py

cd ../terraform
terraform apply -var-file="environments/demo-with-data.tfvars"
```

### Error: "Table not found" for contact_records

**Cause**: No call data processed yet, or table creation in progress

**Solution**:
1. Make test calls in Connect to generate data
2. Wait 30-60 minutes for data processing
3. Check table creation status:
   ```bash
   aws glue get-tables --database-name connect_data_lake --query "TableList[?Name=='contact_records']"
   ```

## 📁 File Structure

```
terraform/
├── environments/
│   ├── demo.tfvars                    # Generic template
│   ├── demo-with-data.tfvars         # Generic template with demo data
│   └── pearson-deployment.tfvars     # Pearson-specific configuration
└── PEARSON_DEPLOYMENT_NOTES.md       # This file
```

## 📋 Deployment Checklist

### Pre-Lake Formation Setup
- [ ] Connect Data Lake enabled in Development (711387125221)
- [ ] Connect Data Lake enabled in Test (124355666805)  
- [ ] Connect Data Lake enabled in Production (816069143691)
- [ ] `connect_data_lake` database exists in all accounts
- [ ] Some call data processed (for table creation)

### Connect Data Lake Sharing Setup
- [ ] Development account shares data to Production (816069143691)
- [ ] Test account shares data to Production (816069143691)
- [ ] Production account has consolidated `connect_data_lake` database
- [ ] Athena queries work across all account data

### Terraform Deployment
- [ ] QuickSight user ARN updated in `pearson-deployment.tfvars`
- [ ] Terraform apply successful
- [ ] Dashboard accessible
- [ ] Data visible in QuickSight

This approach keeps the Terraform code reusable while maintaining Pearson-specific deployment details separately.