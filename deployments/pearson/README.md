# Pearson Connect Analytics Deployment

Customer-specific deployment configuration for Pearson's multi-account Connect analytics solution.

## Account Configuration

- **Production/Analytics**: 816069143691 (receives shared data)
- **Development**: 711387125221 (shares data to Production)
- **Test**: 124355666805 (shares data to Production)

## Quick Deploy

```bash
cd terraform
terraform init
terraform apply -var-file="../deployments/pearson/terraform.tfvars"
```

## Files

- `terraform.tfvars` - Pearson-specific configuration
- `DEPLOYMENT_NOTES.md` - Detailed deployment guide and troubleshooting
- `README.md` - This file

## Database Configuration

Uses `connectanalyticsblog` database (instance-specific name from Connect Data Lake).

## Cross-Account Setup Required

1. Enable Connect Data Lake in all three accounts
2. Configure cross-account sharing to Production account
3. Wait 1-4 hours for data propagation
4. Deploy Terraform configuration

See `DEPLOYMENT_NOTES.md` for detailed instructions and troubleshooting.