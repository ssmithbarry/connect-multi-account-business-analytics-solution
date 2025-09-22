# Pearson Connect Analytics - Lake Formation Cross-Account Setup Script (PowerShell)
# Run this script in each Connect account to grant permissions to the analytics account

# Pearson Configuration
$ANALYTICS_ACCOUNT_ID = "816069143691"  # Pearson Production/Analytics account
$CONNECT_ACCOUNTS = @("711387125221", "124355666805")  # Development and Test accounts
$ALL_ACCOUNTS = @("816069143691", "711387125221", "124355666805")  # All Pearson accounts

Write-Host "🔐 Pearson Connect Analytics - Lake Formation Setup" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Get current account
$CURRENT_ACCOUNT = aws sts get-caller-identity --query Account --output text
Write-Host "Current account: $CURRENT_ACCOUNT" -ForegroundColor Cyan

# Check account type
if ($CONNECT_ACCOUNTS -contains $CURRENT_ACCOUNT) {
    Write-Host "✅ This is a Pearson Connect account (Development or Test)" -ForegroundColor Green
    
    Write-Host "🔑 Granting Lake Formation permissions to analytics account: $ANALYTICS_ACCOUNT_ID" -ForegroundColor Yellow
    
    # Grant database permissions
    Write-Host "   Granting database permissions..." -ForegroundColor White
    aws lakeformation grant-permissions `
        --principal DataLakePrincipalIdentifier=arn:aws:iam::${ANALYTICS_ACCOUNT_ID}:root `
        --permissions "SELECT" "DESCRIBE" `
        --resource '{\"Database\":{\"Name\":\"connect_data_lake\"}}'
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Database permissions granted" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Failed to grant database permissions" -ForegroundColor Red
        exit 1
    }
    
    # Grant table permissions
    Write-Host "   Granting table permissions..." -ForegroundColor White
    aws lakeformation grant-permissions `
        --principal DataLakePrincipalIdentifier=arn:aws:iam::${ANALYTICS_ACCOUNT_ID}:root `
        --permissions "SELECT" "DESCRIBE" `
        --resource '{\"Table\":{\"DatabaseName\":\"connect_data_lake\",\"Name\":\"contact_records\"}}'
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Table permissions granted" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Failed to grant table permissions" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Lake Formation permissions granted successfully!" -ForegroundColor Green
    
    # Verify permissions
    Write-Host "🔍 Verifying permissions..." -ForegroundColor Yellow
    aws lakeformation list-permissions `
        --principal arn:aws:iam::${ANALYTICS_ACCOUNT_ID}:root `
        --query "PrincipalResourcePermissions[?Resource.Database.Name=='connect_data_lake' || Resource.Table.DatabaseName=='connect_data_lake']"
    
} elseif ($CURRENT_ACCOUNT -eq $ANALYTICS_ACCOUNT_ID) {
    Write-Host "✅ This is the analytics account" -ForegroundColor Green
    
    Write-Host "🔍 Checking shared resources..." -ForegroundColor Yellow
    
    # List shared databases
    Write-Host "   Shared databases:" -ForegroundColor White
    aws glue get-databases --query "DatabaseList[?Name=='connect_data_lake']" --output table
    
    # Test Athena access
    Write-Host "   Testing Athena access..." -ForegroundColor White
    $region = aws configure get region
    $QUERY_ID = aws athena start-query-execution `
        --query-string "SHOW TABLES IN connect_data_lake" `
        --result-configuration OutputLocation=s3://aws-athena-query-results-${CURRENT_ACCOUNT}-${region}/ `
        --query "QueryExecutionId" --output text
    
    if ($QUERY_ID) {
        Write-Host "   ✅ Athena query started: $QUERY_ID" -ForegroundColor Green
        Write-Host "   Check Athena console for results" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Failed to start Athena query" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ Unknown account: $CURRENT_ACCOUNT" -ForegroundColor Red
    Write-Host "Expected one of:" -ForegroundColor Yellow
    Write-Host "   Analytics: $ANALYTICS_ACCOUNT_ID" -ForegroundColor Gray
    foreach ($account in $CONNECT_ACCOUNTS) {
        Write-Host "   Connect: $account" -ForegroundColor Gray
    }
    exit 1
}

Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
if ($CONNECT_ACCOUNTS -contains $CURRENT_ACCOUNT) {
    Write-Host "1. Run this script in the other Connect accounts (if any remaining)" -ForegroundColor White
    Write-Host "2. Run this script in the Production/Analytics account (816069143691) to verify" -ForegroundColor White
    Write-Host "3. Deploy Terraform: terraform apply -var-file=`"environments/pearson-deployment.tfvars`"" -ForegroundColor White
} elseif ($CURRENT_ACCOUNT -eq $ANALYTICS_ACCOUNT_ID) {
    Write-Host "1. Verify all Connect accounts have granted permissions" -ForegroundColor White
    Write-Host "2. Deploy Terraform: terraform apply -var-file=`"environments/pearson-deployment.tfvars`"" -ForegroundColor White
    Write-Host "3. Access QuickSight dashboard" -ForegroundColor White
}

Write-Host ""
Write-Host "✨ Lake Formation setup complete for account: $CURRENT_ACCOUNT" -ForegroundColor Green