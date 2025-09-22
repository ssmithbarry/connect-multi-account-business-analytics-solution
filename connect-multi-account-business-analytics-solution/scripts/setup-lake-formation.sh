#!/bin/bash
# Pearson Connect Analytics - Lake Formation Cross-Account Setup Script
# Run this script in each Connect account to grant permissions to the analytics account

set -e

# Pearson Configuration
ANALYTICS_ACCOUNT_ID="816069143691"  # Pearson Production/Analytics account
CONNECT_ACCOUNTS=("711387125221" "124355666805")  # Development and Test accounts
ALL_ACCOUNTS=("816069143691" "711387125221" "124355666805")  # All Pearson accounts

echo "🔐 Pearson Connect Analytics - Lake Formation Setup"
echo "=================================================="

# Get current account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "Current account: $CURRENT_ACCOUNT"

# Check account type
if [[ " ${CONNECT_ACCOUNTS[@]} " =~ " ${CURRENT_ACCOUNT} " ]]; then
    echo "✅ This is a Pearson Connect account (Development or Test)"
    
    echo "🔑 Granting Lake Formation permissions to analytics account: $ANALYTICS_ACCOUNT_ID"
    
    # Grant database permissions
    echo "   Granting database permissions..."
    aws lakeformation grant-permissions \
        --principal DataLakePrincipalIdentifier=arn:aws:iam::${ANALYTICS_ACCOUNT_ID}:root \
        --permissions "SELECT" "DESCRIBE" \
        --resource '{"Database":{"Name":"connect_data_lake"}}'
    
    # Grant table permissions
    echo "   Granting table permissions..."
    aws lakeformation grant-permissions \
        --principal DataLakePrincipalIdentifier=arn:aws:iam::${ANALYTICS_ACCOUNT_ID}:root \
        --permissions "SELECT" "DESCRIBE" \
        --resource '{"Table":{"DatabaseName":"connect_data_lake","Name":"contact_records"}}'
    
    echo "✅ Lake Formation permissions granted successfully!"
    
    # Verify permissions
    echo "🔍 Verifying permissions..."
    aws lakeformation list-permissions \
        --principal arn:aws:iam::${ANALYTICS_ACCOUNT_ID}:root \
        --query "PrincipalResourcePermissions[?Resource.Database.Name=='connect_data_lake' || Resource.Table.DatabaseName=='connect_data_lake']"
    
elif [ "$CURRENT_ACCOUNT" = "$ANALYTICS_ACCOUNT_ID" ]; then
    echo "✅ This is the analytics account"
    
    echo "🔍 Checking shared resources..."
    
    # List shared databases
    echo "   Shared databases:"
    aws glue get-databases --query "DatabaseList[?Name=='connect_data_lake']" --output table
    
    # Test Athena access
    echo "   Testing Athena access..."
    QUERY_ID=$(aws athena start-query-execution \
        --query-string "SHOW TABLES IN connect_data_lake" \
        --result-configuration OutputLocation=s3://aws-athena-query-results-${CURRENT_ACCOUNT}-$(aws configure get region)/ \
        --query "QueryExecutionId" --output text)
    
    echo "   Athena query started: $QUERY_ID"
    echo "   Check Athena console for results"
    
else
    echo "❌ Unknown account: $CURRENT_ACCOUNT"
    echo "Expected one of:"
    printf "   Analytics: %s\n" "$ANALYTICS_ACCOUNT_ID"
    printf "   Connect: %s\n" "${CONNECT_ACCOUNTS[@]}"
    exit 1
fi

echo ""
echo "🎯 Next Steps:"
if [[ " ${CONNECT_ACCOUNTS[@]} " =~ " ${CURRENT_ACCOUNT} " ]]; then
    echo "1. Run this script in the other Connect accounts (if any remaining)"
    echo "2. Run this script in the Production/Analytics account (816069143691) to verify"
    echo "3. Deploy Terraform: terraform apply -var-file=\"environments/pearson-deployment.tfvars\""
elif [ "$CURRENT_ACCOUNT" = "$ANALYTICS_ACCOUNT_ID" ]; then
    echo "1. Verify all Connect accounts have granted permissions"
    echo "2. Deploy Terraform: terraform apply -var-file=\"environments/pearson-deployment.tfvars\""
    echo "3. Access QuickSight dashboard"
fi

echo ""
echo "✨ Lake Formation setup complete for account: $CURRENT_ACCOUNT"