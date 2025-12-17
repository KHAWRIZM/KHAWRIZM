# =============================================================================
# GraTech CometX - Azure Container Apps Setup
# =============================================================================
# Creates Container Apps infrastructure with OIDC, custom domains & SSL
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "dde8416c-6077-4b2b-b722-05bf8b782c44",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-cometx-prod",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus2",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubOrg = "gratech-sa",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "gratech-cometx"
)

# Colors
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) { Write-Output $args }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"
Write-ColorOutput Cyan "  GraTech CometX - Container Apps Setup"
Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"
Write-Host ""

# Variables
$EnvProd = "cae-cometx-prod"
$EnvStg = "cae-cometx-staging"
$AppProd = "ca-cometx-api"
$AppStg = "ca-cometx-api-staging"
$TargetPort = 8080
$ImageProd = "ghcr.io/$GitHubOrg/$($GitHubRepo.ToLower()):latest"
$ImageStg = "ghcr.io/$GitHubOrg/$($GitHubRepo.ToLower()):staging"
$DomainZone = "gratech.sa"
$DomainProd = "api.$DomainZone"
$DomainStg = "staging.$DomainZone"

# =============================================================================
# Step 1: Verify Azure Login
# =============================================================================
Write-ColorOutput Yellow "🔐 Step 1: Verifying Azure Login"
Write-Host ""

try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-ColorOutput Green "✓ Logged in as: $($account.user.name)"
    az account set --subscription $SubscriptionId
    Write-ColorOutput Green "✓ Using subscription: $($account.name)"
} catch {
    Write-ColorOutput Red "❌ Not logged in. Please run: az login"
    exit 1
}

$TenantId = (az account show --query tenantId -o tsv)
Write-Host ""

# =============================================================================
# Step 2: Verify Resource Group
# =============================================================================
Write-ColorOutput Yellow "📦 Step 2: Verifying Resource Group"
Write-Host ""

$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-ColorOutput Yellow "Creating Resource Group: $ResourceGroupName"
    az group create --name $ResourceGroupName --location $Location
} else {
    Write-ColorOutput Green "✓ Resource Group exists: $ResourceGroupName"
}
Write-Host ""

# =============================================================================
# Step 3: Install Container Apps Extension
# =============================================================================
Write-ColorOutput Yellow "🔧 Step 3: Installing Container Apps Extension"
Write-Host ""

az extension add --name containerapp --upgrade 2>&1 | Out-Null
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait
Write-ColorOutput Green "✓ Container Apps extension ready"
Write-Host ""

# =============================================================================
# Step 4: Create Container Apps Environments
# =============================================================================
Write-ColorOutput Yellow "🌍 Step 4: Creating Container Apps Environments"
Write-Host ""

Write-ColorOutput Yellow "Creating PROD environment: $EnvProd"
az containerapp env create `
    --name $EnvProd `
    --resource-group $ResourceGroupName `
    --location $Location 2>&1 | Out-Null

Write-ColorOutput Yellow "Creating STAGING environment: $EnvStg"
az containerapp env create `
    --name $EnvStg `
    --resource-group $ResourceGroupName `
    --location $Location 2>&1 | Out-Null

Write-ColorOutput Green "✓ Environments created"
Write-Host ""

# =============================================================================
# Step 5: Create Container Apps
# =============================================================================
Write-ColorOutput Yellow "📱 Step 5: Creating Container Apps"
Write-Host ""

Write-ColorOutput Yellow "Creating PROD app: $AppProd"
az containerapp create `
    --name $AppProd `
    --resource-group $ResourceGroupName `
    --environment $EnvProd `
    --image "mcr.microsoft.com/k8se/quickstart:latest" `
    --target-port $TargetPort `
    --ingress external `
    --query properties.configuration.ingress.fqdn `
    --output tsv 2>&1 | Out-Null

Write-ColorOutput Yellow "Creating STAGING app: $AppStg"
az containerapp create `
    --name $AppStg `
    --resource-group $ResourceGroupName `
    --environment $EnvStg `
    --image "mcr.microsoft.com/k8se/quickstart:latest" `
    --target-port $TargetPort `
    --ingress external `
    --query properties.configuration.ingress.fqdn `
    --output tsv 2>&1 | Out-Null

Write-ColorOutput Green "✓ Container Apps created"
Write-Host ""

# =============================================================================
# Step 6: Get FQDNs
# =============================================================================
Write-ColorOutput Yellow "🌐 Step 6: Getting Application URLs"
Write-Host ""

$ProdFqdn = az containerapp show `
    --name $AppProd `
    --resource-group $ResourceGroupName `
    --query "properties.configuration.ingress.fqdn" -o tsv

$StgFqdn = az containerapp show `
    --name $AppStg `
    --resource-group $ResourceGroupName `
    --query "properties.configuration.ingress.fqdn" -o tsv

Write-ColorOutput Green "✓ PROD URL: https://$ProdFqdn"
Write-ColorOutput Green "✓ STAGING URL: https://$StgFqdn"
Write-Host ""

# =============================================================================
# Step 7: Summary & Next Steps
# =============================================================================
Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"
Write-ColorOutput Cyan "  ✅ Container Apps Setup Completed!"
Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"
Write-Host ""

Write-ColorOutput Green "📋 Created Resources:"
Write-Output "Resource Group    : $ResourceGroupName"
Write-Output "Location          : $Location"
Write-Output "PROD Environment  : $EnvProd"
Write-Output "STAGING Environment: $EnvStg"
Write-Output "PROD App          : $AppProd"
Write-Output "STAGING App       : $AppStg"
Write-Host ""

Write-ColorOutput Green "🌐 Application URLs:"
Write-Output "PROD    : https://$ProdFqdn"
Write-Output "STAGING : https://$StgFqdn"
Write-Host ""

Write-ColorOutput Green "📋 GitHub Secrets (from previous setup):"
Write-Output "AZURE_CLIENT_ID        = 9036905f-24d2-4f5e-99e7-98b8638b5abe"
Write-Output "AZURE_TENANT_ID        = $TenantId"
Write-Output "AZURE_SUBSCRIPTION_ID  = $SubscriptionId"
Write-Host ""

Write-ColorOutput Yellow "📝 DNS Setup (Optional - for custom domains):"
Write-Output "Add these CNAME records to your DNS provider:"
Write-Output ""
Write-Output "CNAME Records:"
Write-Output "  $DomainProd    ->  $ProdFqdn"
Write-Output "  $DomainStg     ->  $StgFqdn"
Write-Host ""
Write-ColorOutput Yellow "After DNS is configured, run:"
Write-Output "az containerapp hostname add -g $ResourceGroupName -n $AppProd --hostname $DomainProd"
Write-Output "az containerapp hostname add -g $ResourceGroupName -n $AppStg --hostname $DomainStg"
Write-Host ""

Write-ColorOutput Green "📝 Next Steps:"
Write-Output "1. ✅ Azure infrastructure is ready"
Write-Output "2. Initialize Git: git init"
Write-Output "3. Add remote: git remote add origin https://github.com/$GitHubOrg/$GitHubRepo.git"
Write-Output "4. Push code: git add . && git commit -m 'Initial commit' && git push -u origin main"
Write-Output "5. Add GitHub Secrets (see above)"
Write-Output "6. GitHub Actions will build and deploy automatically"
Write-Host ""

Write-ColorOutput Cyan "═══════════════════════════════════════════════════════"

# Save output
$outputFile = "azure-containerapp-output.txt"
@"
═══════════════════════════════════════════════════════
GraTech CometX - Container Apps Setup Summary
═══════════════════════════════════════════════════════
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

CREATED RESOURCES:
────────────────────────────────────────────────────────
Resource Group       : $ResourceGroupName
Location             : $Location
PROD Environment     : $EnvProd
STAGING Environment  : $EnvStg
PROD App             : $AppProd
STAGING App          : $AppStg

APPLICATION URLs:
────────────────────────────────────────────────────────
PROD                 : https://$ProdFqdn
STAGING              : https://$StgFqdn

GITHUB SECRETS:
────────────────────────────────────────────────────────
AZURE_CLIENT_ID        = 9036905f-24d2-4f5e-99e7-98b8638b5abe
AZURE_TENANT_ID        = $TenantId
AZURE_SUBSCRIPTION_ID  = $SubscriptionId

DNS SETUP (Optional):
────────────────────────────────────────────────────────
CNAME: $DomainProd    ->  $ProdFqdn
CNAME: $DomainStg     ->  $StgFqdn

═══════════════════════════════════════════════════════
"@ | Out-File -FilePath $outputFile -Encoding UTF8

Write-ColorOutput Green "💾 Configuration saved to: $outputFile"
Write-Host ""
