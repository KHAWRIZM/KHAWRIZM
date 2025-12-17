# =============================================================================
# GraTech CometX - Azure Setup Script
# =============================================================================
# This script sets up Azure resources with OIDC authentication for GitHub Actions
# No secrets stored - uses Workload Identity Federation
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-cometx-prod",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westeurope",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubOrg = "gratech-sa",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "gratech-cometx",
    
    [Parameter(Mandatory=$false)]
    [switch]$DeleteExisting
)

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"
Write-ColorOutput Cyan "  GraTech CometX - Azure Infrastructure Setup"
Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"
Write-Host ""

# =============================================================================
# Step 1: Login and Set Subscription
# =============================================================================
Write-ColorOutput Yellow "🔐 Step 1: Azure Login"
Write-Host ""

try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-ColorOutput Green "✓ Already logged in as: $($account.user.name)"
} catch {
    Write-ColorOutput Yellow "⚠ Not logged in. Opening browser..."
    az login
}

if ($SubscriptionId) {
    Write-ColorOutput Yellow "Setting subscription: $SubscriptionId"
    az account set --subscription $SubscriptionId
} else {
    $currentSub = az account show | ConvertFrom-Json
    $SubscriptionId = $currentSub.id
    Write-ColorOutput Green "✓ Using current subscription: $($currentSub.name)"
}

$TenantId = (az account show --query tenantId -o tsv)
Write-Host ""

# =============================================================================
# Step 2: Delete Existing Resources (Optional)
# =============================================================================
if ($DeleteExisting) {
    Write-ColorOutput Yellow "🗑️  Step 2: Deleting Existing Resources"
    Write-Host ""
    
    Write-ColorOutput Red "⚠️  WARNING: This will DELETE all resources in Resource Group: $ResourceGroupName"
    $confirm = Read-Host "Type 'DELETE' to confirm"
    
    if ($confirm -eq "DELETE") {
        $rgExists = az group exists --name $ResourceGroupName
        if ($rgExists -eq "true") {
            Write-ColorOutput Yellow "Deleting resource group $ResourceGroupName..."
            az group delete --name $ResourceGroupName --yes --no-wait
            Write-ColorOutput Green "✓ Deletion initiated (running in background)"
        } else {
            Write-ColorOutput Yellow "⚠ Resource group does not exist, skipping"
        }
    } else {
        Write-ColorOutput Yellow "⚠ Deletion cancelled"
    }
    Write-Host ""
}

# =============================================================================
# Step 3: Create App Registration with OIDC
# =============================================================================
Write-ColorOutput Yellow "🔑 Step 3: Creating App Registration with OIDC"
Write-Host ""

$AppName = "gratech-cometx-oidc"

# Check if app already exists
$existingApp = az ad app list --display-name $AppName | ConvertFrom-Json
if ($existingApp.Count -gt 0) {
    Write-ColorOutput Yellow "⚠ App '$AppName' already exists. Deleting..."
    az ad app delete --id $existingApp[0].appId
    Start-Sleep -Seconds 5
}

# Create new app
Write-ColorOutput Yellow "Creating App Registration: $AppName"
$app = az ad app create --display-name $AppName | ConvertFrom-Json
$AppId = $app.appId
Write-ColorOutput Green "✓ App ID: $AppId"

# Create Service Principal
Write-ColorOutput Yellow "Creating Service Principal..."
$sp = az ad sp create --id $AppId | ConvertFrom-Json
$SpObjectId = $sp.id
Write-ColorOutput Green "✓ Service Principal ID: $SpObjectId"

# Wait for propagation
Write-ColorOutput Yellow "Waiting for Azure AD propagation..."
Start-Sleep -Seconds 15

# Assign Contributor role
Write-ColorOutput Yellow "Assigning Contributor role..."
az role assignment create `
    --assignee-object-id $SpObjectId `
    --assignee-principal-type ServicePrincipal `
    --role "Contributor" `
    --scope "/subscriptions/$SubscriptionId"
Write-ColorOutput Green "✓ Role assigned"

# Add Federated Credential for main branch
Write-ColorOutput Yellow "Adding Federated Credential for main branch..."
$FedCredMain = @{
    name = "github-oidc-main"
    issuer = "https://token.actions.githubusercontent.com"
    subject = "repo:$GitHubOrg/$GitHubRepo:ref:refs/heads/main"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Depth 10

$FedCredMain | az ad app federated-credential create --id $AppId --parameters '@-'
Write-ColorOutput Green "✓ Federated credential created for main branch"

# Add Federated Credential for pull requests
Write-ColorOutput Yellow "Adding Federated Credential for pull requests..."
$FedCredPR = @{
    name = "github-oidc-pr"
    issuer = "https://token.actions.githubusercontent.com"
    subject = "repo:$GitHubOrg/$GitHubRepo:pull_request"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Depth 10

$FedCredPR | az ad app federated-credential create --id $AppId --parameters '@-'
Write-ColorOutput Green "✓ Federated credential created for pull requests"

Write-Host ""

# =============================================================================
# Step 4: Create Resource Group
# =============================================================================
Write-ColorOutput Yellow "📦 Step 4: Creating Resource Group"
Write-Host ""

az group create --name $ResourceGroupName --location $Location
Write-ColorOutput Green "✓ Resource Group: $ResourceGroupName"
Write-Host ""

# =============================================================================
# Step 5: Create App Service Plan & Web App
# =============================================================================
Write-ColorOutput Yellow "🌐 Step 5: Creating App Service Plan & Web App"
Write-Host ""

$AppServicePlan = "asp-cometx-prod"
$WebAppName = "app-cometx-web"

Write-ColorOutput Yellow "Creating App Service Plan: $AppServicePlan"
az appservice plan create `
    --name $AppServicePlan `
    --resource-group $ResourceGroupName `
    --location $Location `
    --is-linux `
    --sku P1v3
Write-ColorOutput Green "✓ App Service Plan created"

Write-ColorOutput Yellow "Creating Web App: $WebAppName"
az webapp create `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --plan $AppServicePlan `
    --deployment-container-image-name "nginx:alpine"
Write-ColorOutput Green "✓ Web App created"

Write-ColorOutput Yellow "Configuring Web App settings..."
az webapp config set `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --always-on true `
    --http20-enabled true

az webapp config container set `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --docker-custom-image-name "ghcr.io/$GitHubOrg/$($GitHubRepo.ToLower()):latest" `
    --docker-registry-server-url "https://ghcr.io"

Write-ColorOutput Green "✓ Web App configured"
Write-Host ""

# =============================================================================
# Step 6: Summary & Next Steps
# =============================================================================
Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"
Write-ColorOutput Cyan "  ✅ Setup Completed Successfully!"
Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"
Write-Host ""

Write-ColorOutput Green "📋 GitHub Secrets - Add these to your repository:"
Write-Host ""
Write-ColorOutput Yellow "Repository → Settings → Secrets and variables → Actions → New repository secret"
Write-Host ""
Write-Output "AZURE_CLIENT_ID        = $AppId"
Write-Output "AZURE_TENANT_ID        = $TenantId"
Write-Output "AZURE_SUBSCRIPTION_ID  = $SubscriptionId"
Write-Host ""

Write-ColorOutput Green "🌐 Web App URL:"
Write-Output "https://$WebAppName.azurewebsites.net"
Write-Host ""

Write-ColorOutput Green "📝 Next Steps:"
Write-Output "1. Add the GitHub Secrets above to your repository"
Write-Output "2. Push your code to the 'main' branch"
Write-Output "3. GitHub Actions will automatically build and deploy"
Write-Output "4. (Optional) Configure custom domain in Azure Portal"
Write-Host ""

Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"

# Save output to file
$outputFile = "azure-setup-output.txt"
@"
═══════════════════════════════════════════════════════
GraTech CometX - Azure Setup Summary
═══════════════════════════════════════════════════════
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

GITHUB SECRETS (Add to Repository Settings):
────────────────────────────────────────────────────────
AZURE_CLIENT_ID        = $AppId
AZURE_TENANT_ID        = $TenantId
AZURE_SUBSCRIPTION_ID  = $SubscriptionId

AZURE RESOURCES:
────────────────────────────────────────────────────────
Resource Group    : $ResourceGroupName
Location          : $Location
App Service Plan  : $AppServicePlan
Web App Name      : $WebAppName
Web App URL       : https://$WebAppName.azurewebsites.net

APP REGISTRATION:
────────────────────────────────────────────────────────
App Name          : $AppName
App ID            : $AppId
SP Object ID      : $SpObjectId
Auth Method       : OIDC (Federated Credentials)

OIDC SUBJECTS:
────────────────────────────────────────────────────────
Main Branch       : repo:$GitHubOrg/$GitHubRepo:ref:refs/heads/main
Pull Requests     : repo:$GitHubOrg/$GitHubRepo:pull_request

═══════════════════════════════════════════════════════
"@ | Out-File -FilePath $outputFile -Encoding UTF8

Write-ColorOutput Green "💾 Configuration saved to: $outputFile"
Write-Host ""
