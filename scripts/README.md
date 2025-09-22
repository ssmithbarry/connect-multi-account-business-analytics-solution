# Demo Data Generator for Connect Analytics

## 🎯 Purpose

Creates realistic dummy data for visualization **without interfering** with the actual Connect Data Lake. This allows you to:

- **Demo the dashboard** with realistic data
- **Test visualizations** before real Connect data is available  
- **Show proof of concept** to stakeholders
- **Validate the analytics setup** end-to-end

## 🔒 Safe Design

### No Interference with Connect Data Lake
- Creates separate `demo_contact_records` table alongside real `contact_records`
- Uses separate S3 bucket (`connect-demo-data-ACCOUNT_ID`)
- Creates demo-specific Athena views (`demo_cost_analysis`, `demo_executive_summary`)
- Real Connect data remains untouched

### Realistic Data Generation
- **30 days** of historical call data
- **~150 calls per day** across 3 accounts (production, development, test)
- **Realistic agents, queues, and call patterns**
- **Account-specific cost rates** (prod: $0.025, dev: $0.020, test: $0.015)
- **Proper call durations** (30 seconds to 20 minutes)
- **Realistic disconnect reasons** with proper distribution

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd scripts
pip install -r requirements.txt
```

### 2. Generate Demo Data
```bash
python generate-demo-data.py
```

**Expected Output:**
```
🚀 Pearson Connect Analytics - Demo Data Generator
=======================================================
🎲 Generating demo contact records...
   Generated 4,500 contact records across 30 days
📤 Uploading demo data to S3...
   Created S3 bucket: connect-demo-data-123456789012
   Uploaded to s3://connect-demo-data-123456789012/demo-data/contact_records/demo_data_20241218_143022.parquet
🗃️  Creating demo table in Glue catalog...
   Created table: connect_data_lake.demo_contact_records
📊 Creating demo-specific Athena views...
   ✅ Creating demo cost analysis view
   ✅ Creating demo executive summary view

✅ Demo data generation complete!
📊 Generated 4,500 contact records
🗃️  Table: connect_data_lake.demo_contact_records
📈 Views: demo_cost_analysis, demo_executive_summary
```

### 3. Deploy Terraform with Demo Data
```bash
cd ../terraform
terraform apply -var-file="environments/demo-with-data.tfvars"
```

### 4. Verify in QuickSight
- Access your dashboard URL from Terraform output
- You should see realistic data in all visualizations
- Data spans 30 days with realistic patterns

## 📊 Generated Data Structure

### Contact Records Schema
```sql
CREATE TABLE demo_contact_records (
  contact_id string,           -- Unique contact identifier
  aws_account_id string,       -- Account ID (production/dev/test)
  initiation_timestamp timestamp,  -- Call start time
  disconnect_timestamp timestamp,  -- Call end time  
  channel string,              -- VOICE, CHAT, TASK
  queue_name string,           -- Sales, Support, Billing, etc.
  agent_username string,       -- alice.johnson, bob.smith, etc.
  disconnect_reason string,    -- CUSTOMER_DISCONNECT, AGENT_DISCONNECT, etc.
  initiation_method string,    -- INBOUND, OUTBOUND, TRANSFER, CALLBACK
  instance_arn string          -- Connect instance ARN
)
```

### Account Distribution
- **Production (111111111111)**: 5 agents, 4 queues, $0.025/min
- **Development (222222222222)**: 4 agents, 3 queues, $0.020/min  
- **Test (333333333333)**: 3 agents, 2 queues, $0.015/min

### Call Patterns
- **Business Hours**: 8 AM - 6 PM
- **Duration Range**: 30 seconds to 20 minutes
- **Daily Volume**: 120-180 calls per account (varies randomly)
- **Disconnect Distribution**: 60% customer, 25% agent, 15% other

## 🔧 Using Demo Data in Terraform

### Option 1: Enable Demo Dataset (Recommended)
```hcl
# In your .tfvars file
enable_demo_data = true
```

This creates an additional QuickSight dataset pointing to demo data.

### Option 2: Modify Existing Dataset
Update the main dataset to point to `demo_contact_records` table instead of `contact_records`.

### Option 3: Create Manual Dataset
1. Go to QuickSight console
2. Create new dataset
3. Point to `connect_data_lake.demo_contact_records`
4. Use the same calculated fields as the main dataset

## 🧹 Cleanup Demo Data

### Remove Demo Resources
```bash
# Delete S3 bucket
aws s3 rb s3://connect-demo-data-ACCOUNT_ID --force

# Drop Glue table
aws glue delete-table --database-name connect_data_lake --name demo_contact_records

# Drop Athena views
aws athena start-query-execution --query-string "DROP VIEW connect_data_lake.demo_cost_analysis"
aws athena start-query-execution --query-string "DROP VIEW connect_data_lake.demo_executive_summary"
```

### Disable in Terraform
```hcl
# In your .tfvars file
enable_demo_data = false
```

## 🎯 Demo Scenarios

### Executive Dashboard Demo
- Show cost trends across 3 accounts
- Highlight cost differences between environments
- Demonstrate agent performance tracking

### Cost Analysis Demo
- Filter by account (production vs development vs test)
- Show daily/weekly cost trends
- Identify top-cost agents and queues

### Operational Metrics Demo
- Call volume by channel (voice, chat, task)
- Disconnect reason analysis
- Queue performance comparison

## 🔍 Verification Queries

### Check Demo Data
```sql
-- Count records by account
SELECT 
  aws_account_id,
  COUNT(*) as call_count,
  MIN(initiation_timestamp) as earliest_call,
  MAX(initiation_timestamp) as latest_call
FROM connect_data_lake.demo_contact_records 
GROUP BY aws_account_id;

-- Sample cost analysis
SELECT * FROM connect_data_lake.demo_cost_analysis LIMIT 10;

-- Executive summary
SELECT * FROM connect_data_lake.demo_executive_summary;
```

## ⚠️ Important Notes

1. **Demo Data Only**: This is synthetic data for demonstration purposes
2. **No Real PII**: All names, IDs, and contact information are fake
3. **Separate from Production**: Won't affect real Connect Data Lake
4. **Temporary Use**: Intended for demos, testing, and proof of concepts
5. **Cost Consideration**: S3 storage costs apply (minimal for demo data)

---

**Result**: Realistic demo data for compelling visualizations without touching production Connect data! 🎉