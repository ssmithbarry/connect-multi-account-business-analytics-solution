# Amazon Connect Multi-Account Business Analytics Solution

A comprehensive Terraform-based solution for creating QuickSight dashboards and analytics from Amazon Connect data across multiple AWS accounts using Connect Data Lake.

## 🚀 Quick Start

### CloudShell Demo (Recommended)
```bash
git clone https://github.com/your-repo/connect-multi-account-business-analytics-solution.git
cd connect-multi-account-business-analytics-solution
pip install -r requirements.txt
cd terraform
terraform init
terraform apply -var-file="environments/demo-with-data.tfvars"
```

### Local Development
```bash
git clone https://github.com/your-repo/connect-multi-account-business-analytics-solution.git
cd connect-multi-account-business-analytics-solution
pip install -r scripts/requirements.txt
cd terraform
terraform init
terraform apply -var-file="environments/demo.tfvars"
```

## 📁 Repository Structure

```
connect-multi-account-business-analytics-solution/
├── terraform/                    # Reusable Terraform templates
│   ├── main.tf                   # Root configuration
│   ├── modules/connect-analytics/ # Core analytics module
│   └── environments/             # Template configurations
├── scripts/                      # Utility scripts
│   └── generate-demo-data.py     # Demo data generator
├── sql/                         # SQL queries and examples
├── docs/                        # Documentation
└── deployments/                 # Customer-specific deployments
    └── pearson/                 # Example customer deployment
```

## 🎯 Features

- **QuickSight Dashboard**: Pre-built dashboard with 3 key visualizations
- **Cross-Account Support**: Consolidates data from multiple Connect instances
- **Demo Data Generation**: Creates realistic sample data for testing
- **Cost Analysis**: Account-specific cost tracking and variance analysis
- **Terraform Modules**: Reusable infrastructure as code

## 📊 Dashboard Visualizations

1. **Contact Volume by Account** - Bar chart showing call distribution
2. **Cost Analysis by Account** - Cost breakdown with variance indicators
3. **Daily Contact Trends** - Time series showing contact patterns

## 🛠️ Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (>= 1.0)
- Python 3.7+ (for demo data generation)
- Amazon Connect Data Lake enabled
- QuickSight Enterprise edition

## 📖 Documentation

- [CloudShell Demo Guide](docs/CLOUDSHELL_DEMO.md) - Quick demo setup
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Detailed deployment instructions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🏢 Customer Deployments

Customer-specific configurations are stored in `deployments/[customer-name]/`:
- `terraform.tfvars` - Customer-specific variables
- `DEPLOYMENT_NOTES.md` - Customer-specific deployment notes
- `README.md` - Customer deployment guide

## 🔧 Configuration

### Basic Configuration
```hcl
# terraform.tfvars
aws_region = "us-east-1"
connect_database_name = "connect_data_lake"
quicksight_user_arn = "arn:aws:quicksight:us-east-1:123456789012:user/default/username"
```

### Multi-Account Configuration
```hcl
# For cross-account Connect Data Lake sharing
production_account_id = "123456789012"
development_account_id = "234567890123"
test_account_id = "345678901234"
```

## 🚀 Deployment Options

### Option 1: Demo with Sample Data
```bash
terraform apply -var-file="environments/demo-with-data.tfvars"
```

### Option 2: Production with Real Data
```bash
terraform apply -var-file="deployments/[customer]/terraform.tfvars"
```

## 🧹 Cleanup

```bash
terraform destroy -var-file="environments/demo-with-data.tfvars"
```

## 📝 License

This solution is provided as-is for demonstration and educational purposes.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📞 Support

For issues and questions:
- Check [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- Review [Deployment Notes](deployments/pearson/DEPLOYMENT_NOTES.md) for common scenarios
- Open an issue in this repository