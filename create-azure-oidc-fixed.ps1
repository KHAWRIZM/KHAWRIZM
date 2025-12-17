# إنشاء OIDC لـ GitHub Actions → Azure (بدون مشاكل JSON)
$ErrorActionPreference = 'Stop'

$SUBSCRIPTION_ID = 'dde8416c-6077-4b2b-b722-05bf8b782c44'
$APP_NAME        = 'gratech-cometx-oidc'
$GITHUB_OWNER    = 'gratech-sa'
$GITHUB_REPO     = 'gratech-cometx'

Write-Host "`n🔐 إنشاء/تحديث OIDC Setup..." -ForegroundColor Cyan

az account set --subscription $SUBSCRIPTION_ID

# تحقق من وجود App Registration
$existingApp = az ad app list --filter "displayName eq '$APP_NAME'" --query "[0]" | ConvertFrom-Json
if ($existingApp) {
    Write-Host "✓ App Registration موجود: $($existingApp.appId)" -ForegroundColor Yellow
    $APP_ID = $existingApp.appId
} else {
    Write-Host "✓ إنشاء App Registration جديد..." -ForegroundColor Green
    $app = az ad app create --display-name $APP_NAME | ConvertFrom-Json
    $APP_ID = $app.appId
}

# تحقق من Service Principal
$existingSP = az ad sp list --filter "appId eq '$APP_ID'" --query "[0]" | ConvertFrom-Json
if ($existingSP) {
    Write-Host "✓ Service Principal موجود" -ForegroundColor Yellow
    $SP_OBJECT_ID = $existingSP.id
} else {
    Write-Host "✓ إنشاء Service Principal..." -ForegroundColor Green
    $sp = az ad sp create --id $APP_ID | ConvertFrom-Json
    $SP_OBJECT_ID = $sp.id
}

# دور Contributor (تحقق من وجوده أولاً)
$existingRole = az role assignment list --assignee $SP_OBJECT_ID --scope "/subscriptions/$SUBSCRIPTION_ID" --query "[?roleDefinitionName=='Contributor']" | ConvertFrom-Json
if (-not $existingRole) {
    Write-Host "✓ إضافة دور Contributor..." -ForegroundColor Green
    az role assignment create `
        --assignee-object-id $SP_OBJECT_ID `
        --assignee-principal-type ServicePrincipal `
        --role "Contributor" `
        --scope "/subscriptions/$SUBSCRIPTION_ID"
} else {
    Write-Host "✓ دور Contributor موجود مسبقاً" -ForegroundColor Yellow
}

# إنشاء ملفات JSON للـ Federated Credentials
Write-Host "`n📄 إنشاء ملفات JSON للـ Federated Credentials..." -ForegroundColor Cyan

$jsonMain = @"
{
  "name": "github-oidc-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$GITHUB_OWNER/${GITHUB_REPO}:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}
"@

$jsonStaging = @"
{
  "name": "github-oidc-staging",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$GITHUB_OWNER/${GITHUB_REPO}:ref:refs/heads/staging",
  "audiences": ["api://AzureADTokenExchange"]
}
"@

$jsonMain | Set-Content -Path "fic-main.json" -Encoding UTF8
$jsonStaging | Set-Content -Path "fic-staging.json" -Encoding UTF8

# إضافة/تحديث Federated Credentials
Write-Host "`n🔗 إضافة Federated Credentials..." -ForegroundColor Cyan

# Main branch
$existingMainCred = az ad app federated-credential list --id $APP_ID --query "[?name=='github-oidc-main']" | ConvertFrom-Json
if ($existingMainCred) {
    Write-Host "✓ Credential لـ main موجود مسبقاً" -ForegroundColor Yellow
} else {
    az ad app federated-credential create --id $APP_ID --parameters fic-main.json
    Write-Host "✓ تم إنشاء Credential لـ main" -ForegroundColor Green
}

# Staging branch
$existingStagingCred = az ad app federated-credential list --id $APP_ID --query "[?name=='github-oidc-staging']" | ConvertFrom-Json
if ($existingStagingCred) {
    Write-Host "✓ Credential لـ staging موجود مسبقاً" -ForegroundColor Yellow
} else {
    az ad app federated-credential create --id $APP_ID --parameters fic-staging.json
    Write-Host "✓ تم إنشاء Credential لـ staging" -ForegroundColor Green
}

# حذف الملفات المؤقتة
Remove-Item fic-main.json, fic-staging.json -ErrorAction SilentlyContinue

# عرض القيم النهائية
$TENANT_ID = az account show --query tenantId -o tsv

Write-Host "`n════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ GitHub Secrets - أضفها في المستودع:" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "AZURE_CLIENT_ID = $APP_ID" -ForegroundColor Cyan
Write-Host "AZURE_TENANT_ID = $TENANT_ID" -ForegroundColor Cyan
Write-Host "AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 الرابط: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/settings/secrets/actions" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
