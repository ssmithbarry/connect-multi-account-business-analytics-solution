# Pearson Connect Analytics - CloudShell Demo Guide

## 🎯 **Perfect for Customer Demonstrations**

CloudShell provides a clean, consistent environment with all tools pre-installed:
- ✅ **AWS CLI** configured automatically
- ✅ **Python 3** with pip
- ✅ **Terraform** pre-installed
- ✅ **Git** for cloning repositories
- ✅ **No local setup** required

## 🚀 **CloudShell Demo Steps**

### **1. Open AWS CloudShell**
- Go to AWS Console → CloudShell (top navigation bar)
- Wait for environment to initialize (~30 seconds)

### **2. Clone and Setup Repository**
```bash
# Clone the repository (or upload files)
git clone <YOUR_REPO_URL> pearson-connect-analytics
# OR upload the terraform folder via CloudShell

cd pearson-connect-analytics

# Install Python dependencies
pip install boto3 pandas pyarrow faker
```

### **3. Generate Demo Data**
```bash
# Generate realistic demo data
cd scripts
python generate-demo-data.py

# Expected output:
# 🚀 Pearson Connect Analytics - Demo Data Generator
# 🎲 Generating demo contact records...
#    Generated 4,500 contact records across 30 days
# 📤 Uploading demo data to S3...
#    Created S3 bucket: connect-demo-data-816069143691
# 🗃️  Creating demo table in Glue catalog...
#    Created table: connectanalyticsblog.demo_contact_records
# ✅ Demo data generation complete!
```

### **4. Deploy Terraform Dashboard**
```bash
# Deploy QuickSight dashboard
cd ../terraform
terraform init
terraform apply -var-file="environments/demo-with-data.tfvars" -auto-approve

# Expected output:
# Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
# 
# Outputs:
# quicksight_dashboard_url = "https://us-east-1.quicksight.aws.amazon.com/sn/dashboards/connect-analytics-analytics-dashboard"
```

### **5. Access Dashboard**
- Click the dashboard URL from Terraform output
- Sign in to QuickSight if prompted
- **Demo the multi-account analytics!**

## 🎬 **Demo Script for Customer**

### **Opening (2 minutes)**
> "Let me show you how we can deploy a complete Connect analytics solution in under 5 minutes using infrastructure as code."

### **Data Generation (1 minute)**
```bash
cd scripts && python generate-demo-data.py
```
> "This script generates 30 days of realistic call data across your three accounts - Production, Development, and Test - with different cost rates for each environment."

### **Infrastructure Deployment (2 minutes)**
```bash
cd ../terraform && terraform apply -var-file="environments/demo-with-data.tfvars" -auto-approve
```
> "Terraform is now creating your QuickSight data source, datasets with calculated fields for cost analysis, and a dashboard with three key visualizations."

### **Dashboard Demo (5 minutes)**
> "Here's your multi-account Connect analytics dashboard showing:
> - **Cost by Account**: Production costs more per minute ($0.025) than Development ($0.020) or Test ($0.015)
> - **Daily Cost Trends**: 30 days of realistic call patterns
> - **Agent Performance**: Top agents by cost across all accounts"

## 🔧 **CloudShell Advantages for Demos**

### **No Environment Issues**
- ✅ **Consistent environment** every time
- ✅ **No "works on my machine"** problems
- ✅ **Customer sees exact same experience**

### **Professional Presentation**
- ✅ **Clean terminal** with AWS branding
- ✅ **Fast execution** (AWS network speeds)
- ✅ **No local firewall/proxy issues**

### **Easy Handoff**
- ✅ **Customer can run same commands** immediately
- ✅ **Share CloudShell session** if needed
- ✅ **Files persist** in CloudShell for 120 days

## 📋 **Pre-Demo Checklist**

### **Before Customer Meeting:**
- [ ] **Upload Terraform files** to CloudShell
- [ ] **Test demo script** end-to-end
- [ ] **Verify QuickSight user ARN** in config files
- [ ] **Confirm account access** (816069143691)

### **During Demo:**
- [ ] **Open CloudShell** in customer's presence
- [ ] **Run commands step-by-step** with narration
- [ ] **Show dashboard URL** in browser
- [ ] **Explain cost calculations** and multi-account benefits

## 🎯 **Demo Talking Points**

### **Infrastructure as Code Benefits**
- "Everything is version controlled and repeatable"
- "No manual clicking through consoles"
- "Easy to deploy across multiple environments"

### **Connect Analytics Value**
- "Consolidated view across all your Connect accounts"
- "Real-time cost tracking with account-specific rates"
- "Agent performance insights across environments"

### **AWS Native Integration**
- "Uses Connect's built-in Data Lake - no custom infrastructure"
- "QuickSight provides enterprise-grade analytics"
- "Scales automatically with your call volume"

## ⚡ **Quick Recovery Commands**

**If demo fails:**
```bash
# Clean up and restart
terraform destroy -auto-approve
rm -rf .terraform*
terraform init
terraform apply -var-file="environments/demo-with-data.tfvars" -auto-approve
```

**If data is missing:**
```bash
# Regenerate demo data
cd scripts && python generate-demo-data.py
```

---

**Total Demo Time: ~8 minutes | Preparation: ~2 minutes**