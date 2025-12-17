#!/usr/bin/env pwsh
# ════════════════════════════════════════════════════════════
# 🔄 Migrate to ACR (No Docker) - نقل بدون Docker
# ════════════════════════════════════════════════════════════

param(
    [string]$ResourceGroup = "rg-gratech-comet",
    [string]$AcrName = "cometxreg",
    [string]$ImageName = "gratech-cometx",
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Continue"

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔄 نقل الصور إلى ACR (بدون Docker)" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ────────────────────────────────────────────────────────────────
# 1️⃣ الحصول على بيانات ACR
# ────────────────────────────────────────────────────────────────
Write-Host "1️⃣  الحصول على بيانات ACR..." -ForegroundColor Yellow
$loginServer = az acr show -n $AcrName --query "loginServer" -o tsv
$credentials = az acr credential show -n $AcrName -o json | ConvertFrom-Json
$username = $credentials.username
$password = $credentials.passwords[0].value

Write-Host "   Login Server: $loginServer" -ForegroundColor Cyan
Write-Host "   Username: $username" -ForegroundColor Cyan
Write-Host "✅ تم الحصول على البيانات`n" -ForegroundColor Green

# ────────────────────────────────────────────────────────────────
# 2️⃣ إنشاء صورة Dockerfile بسيطة (للاختبار)
# ────────────────────────────────────────────────────────────────
Write-Host "2️⃣  فحص Dockerfile..." -ForegroundColor Yellow
if (-not (Test-Path "Dockerfile")) {
    Write-Host "   إنشاء Dockerfile أساسي..." -ForegroundColor Yellow
    @"
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
"@ | Out-File -FilePath "Dockerfile" -Encoding utf8
    Write-Host "✅ تم إنشاء Dockerfile`n" -ForegroundColor Green
} else {
    Write-Host "✅ Dockerfile موجود`n" -ForegroundColor Green
}

# ────────────────────────────────────────────────────────────────
# 3️⃣ بناء الصورة مباشرة في ACR (ACR Build)
# ────────────────────────────────────────────────────────────────
Write-Host "3️⃣  بناء الصورة مباشرة في ACR..." -ForegroundColor Yellow
Write-Host "   (هذه العملية قد تستغرق دقائق...)  " -ForegroundColor Cyan
az acr build `
    --registry $AcrName `
    --image "${ImageName}:${Tag}" `
    --file Dockerfile `
    .

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ تم بناء الصورة بنجاح`n" -ForegroundColor Green
} else {
    Write-Host "`n❌ فشل بناء الصورة" -ForegroundColor Red
    exit 1
}

# ────────────────────────────────────────────────────────────────
# 4️⃣ تحديث Container Apps
# ────────────────────────────────────────────────────────────────
Write-Host "4️⃣  تحديث Container Apps..." -ForegroundColor Yellow

# Production
Write-Host "   تحديث Production..." -ForegroundColor Cyan
az containerapp update `
    --name ca-cometx-api `
    --resource-group $ResourceGroup `
    --image "${loginServer}/${ImageName}:${Tag}" `
    --registry-server $loginServer `
    --registry-username $username `
    --registry-password $password

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Production updated" -ForegroundColor Green
}

# Staging
Write-Host "   تحديث Staging..." -ForegroundColor Cyan
az containerapp update `
    --name ca-cometx-api-staging `
    --resource-group $ResourceGroup `
    --image "${loginServer}/${ImageName}:${Tag}" `
    --registry-server $loginServer `
    --registry-username $username `
    --registry-password $password

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Staging updated`n" -ForegroundColor Green
}

# ────────────────────────────────────────────────────────────────
# 5️⃣ التحقق من الحالة
# ────────────────────────────────────────────────────────────────
Write-Host "5️⃣  التحقق من الحالة..." -ForegroundColor Yellow
$prodApp = az containerapp show --name ca-cometx-api --resource-group $ResourceGroup --query "{fqdn:properties.configuration.ingress.fqdn,image:properties.template.containers[0].image}" -o json | ConvertFrom-Json
$stagingApp = az containerapp show --name ca-cometx-api-staging --resource-group $ResourceGroup --query "{fqdn:properties.configuration.ingress.fqdn,image:properties.template.containers[0].image}" -o json | ConvertFrom-Json

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "🎉 اكتمل النقل بنجاح!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Green

Write-Host "📦 ACR Details:" -ForegroundColor Cyan
Write-Host "   Login Server: $loginServer" -ForegroundColor White
Write-Host "   Username: $username" -ForegroundColor White
Write-Host "   Image: ${loginServer}/${ImageName}:${Tag}`n" -ForegroundColor White

Write-Host "🌐 Container Apps:" -ForegroundColor Cyan
Write-Host "   Production:" -ForegroundColor White
Write-Host "     FQDN: $($prodApp.fqdn)" -ForegroundColor Gray
Write-Host "     Image: $($prodApp.image)" -ForegroundColor Gray
Write-Host "   Staging:" -ForegroundColor White
Write-Host "     FQDN: $($stagingApp.fqdn)" -ForegroundColor Gray
Write-Host "     Image: $($stagingApp.image)`n" -ForegroundColor Gray

Write-Host "📋 GitHub Secrets (أضفها الآن):" -ForegroundColor Yellow
Write-Host "   REGISTRY_USERNAME = $username" -ForegroundColor White
Write-Host "   REGISTRY_PASSWORD = $password" -ForegroundColor White
Write-Host "   ACR_LOGIN_SERVER = $loginServer`n" -ForegroundColor White

Write-Host "🔗 Links:" -ForegroundColor Cyan
Write-Host "   Secrets: https://github.com/Grar00t/gratech-cometx/settings/secrets/actions" -ForegroundColor White
Write-Host "   Production: https://app.gratech.sa" -ForegroundColor White
Write-Host "   Staging: https://staging.gratech.sa`n" -ForegroundColor White

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
