#!/usr/bin/env pwsh
# ════════════════════════════════════════════════════════════
# 🔄 Migrate from GHCR to ACR - نقل الصور من GHCR إلى ACR
# ════════════════════════════════════════════════════════════

param(
    [string]$ResourceGroup = "rg-gratech-comet",
    [string]$AcrName = "gratechacr",
    [string]$GhcrImage = "ghcr.io/Grar00t/gratech-cometx:latest",
    [string]$ImageName = "gratech-cometx",
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Continue"

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔄 نقل الصور من GHCR إلى ACR" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ────────────────────────────────────────────────────────────────
# 1️⃣ فحص وإنشاء ACR
# ────────────────────────────────────────────────────────────────
Write-Host "1️⃣  فحص ACR..." -ForegroundColor Yellow
$acrExists = az acr show -n $AcrName -g $ResourceGroup --query "name" -o tsv 2>$null

if (-not $acrExists) {
    Write-Host "   إنشاء ACR: $AcrName..." -ForegroundColor Yellow
    az acr create -g $ResourceGroup -n $AcrName --sku Basic --admin-enabled true
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ تم إنشاء ACR بنجاح`n" -ForegroundColor Green
    } else {
        Write-Host "❌ فشل إنشاء ACR" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ ACR موجود: $AcrName`n" -ForegroundColor Green
}

# ────────────────────────────────────────────────────────────────
# 2️⃣ الحصول على بيانات الاعتماد
# ────────────────────────────────────────────────────────────────
Write-Host "2️⃣  الحصول على بيانات ACR..." -ForegroundColor Yellow
$loginServer = az acr show -n $AcrName --query "loginServer" -o tsv
$credentials = az acr credential show -n $AcrName -o json | ConvertFrom-Json
$username = $credentials.username
$password = $credentials.passwords[0].value

Write-Host "   Login Server: $loginServer" -ForegroundColor Cyan
Write-Host "   Username: $username" -ForegroundColor Cyan
Write-Host "✅ تم الحصول على البيانات`n" -ForegroundColor Green

# ────────────────────────────────────────────────────────────────
# 3️⃣ تسجيل الدخول إلى ACR
# ────────────────────────────────────────────────────────────────
Write-Host "3️⃣  تسجيل الدخول إلى ACR..." -ForegroundColor Yellow
az acr login -n $AcrName
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ تم تسجيل الدخول`n" -ForegroundColor Green
} else {
    Write-Host "❌ فشل تسجيل الدخول" -ForegroundColor Red
    exit 1
}

# ────────────────────────────────────────────────────────────────
# 4️⃣ سحب الصورة من GHCR
# ────────────────────────────────────────────────────────────────
Write-Host "4️⃣  سحب الصورة من GHCR..." -ForegroundColor Yellow
Write-Host "   Image: $GhcrImage" -ForegroundColor Cyan
docker pull $GhcrImage
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ تم سحب الصورة`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  فشل سحب الصورة من GHCR - ربما لا توجد صورة أو تحتاج مصادقة" -ForegroundColor Yellow
    Write-Host "   سنبني صورة جديدة من المصدر...`n" -ForegroundColor Yellow
    
    # بناء صورة جديدة
    Write-Host "   بناء صورة من المصدر..." -ForegroundColor Yellow
    docker build -t "${loginServer}/${ImageName}:${Tag}" .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ فشل بناء الصورة" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ تم بناء الصورة`n" -ForegroundColor Green
}

# ────────────────────────────────────────────────────────────────
# 5️⃣ إعادة تسمية الصورة
# ────────────────────────────────────────────────────────────────
if ($LASTEXITCODE -eq 0) {
    Write-Host "5️⃣  إعادة تسمية الصورة..." -ForegroundColor Yellow
    docker tag $GhcrImage "${loginServer}/${ImageName}:${Tag}"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ تم إعادة التسمية`n" -ForegroundColor Green
    }
}

# ────────────────────────────────────────────────────────────────
# 6️⃣ دفع الصورة إلى ACR
# ────────────────────────────────────────────────────────────────
Write-Host "6️⃣  دفع الصورة إلى ACR..." -ForegroundColor Yellow
docker push "${loginServer}/${ImageName}:${Tag}"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ تم دفع الصورة بنجاح`n" -ForegroundColor Green
} else {
    Write-Host "❌ فشل دفع الصورة" -ForegroundColor Red
    exit 1
}

# ────────────────────────────────────────────────────────────────
# 7️⃣ تحديث Container Apps
# ────────────────────────────────────────────────────────────────
Write-Host "7️⃣  تحديث Container Apps..." -ForegroundColor Yellow

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
# 8️⃣ التحقق من الحالة
# ────────────────────────────────────────────────────────────────
Write-Host "8️⃣  التحقق من الحالة..." -ForegroundColor Yellow
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
