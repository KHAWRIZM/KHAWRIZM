#!/usr/bin/env pwsh
# تحديث Container Apps بالصورة من ACR

$ACR = "cometxreg"
$RG = "rg-gratech-comet"
$IMAGE = "cometxreg.azurecr.io/gratech-cometx:latest"

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 تحديث Container Apps" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# بيانات ACR
Write-Host "1️⃣  الحصول على بيانات ACR..." -ForegroundColor Yellow
$credentials = az acr credential show -n $ACR -o json | ConvertFrom-Json
$username = $credentials.username
$password = $credentials.passwords[0].value
Write-Host "✅ تم`n" -ForegroundColor Green

# Production
Write-Host "2️⃣  تحديث Production..." -ForegroundColor Yellow
az containerapp update `
    --name ca-cometx-api `
    --resource-group $RG `
    --image $IMAGE `
    --registry-server cometxreg.azurecr.io `
    --registry-username $username `
    --registry-password $password

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Production updated`n" -ForegroundColor Green
}

# Staging
Write-Host "3️⃣  تحديث Staging..." -ForegroundColor Yellow
az containerapp update `
    --name ca-cometx-api-staging `
    --resource-group $RG `
    --image $IMAGE `
    --registry-server cometxreg.azurecr.io `
    --registry-username $username `
    --registry-password $password

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Staging updated`n" -ForegroundColor Green
}

# التحقق
Write-Host "4️⃣  التحقق من الحالة..." -ForegroundColor Yellow
$prod = az containerapp show --name ca-cometx-api --resource-group $RG --query "{fqdn:properties.configuration.ingress.fqdn,image:properties.template.containers[0].image}" -o json | ConvertFrom-Json
$staging = az containerapp show --name ca-cometx-api-staging --resource-group $RG --query "{fqdn:properties.configuration.ingress.fqdn,image:properties.template.containers[0].image}" -o json | ConvertFrom-Json

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "🎉 تم التحديث بنجاح!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Green

Write-Host "🌐 Production:" -ForegroundColor Cyan
Write-Host "   FQDN: $($prod.fqdn)" -ForegroundColor White
Write-Host "   Image: $($prod.image)" -ForegroundColor Gray
Write-Host "   URL: https://app.gratech.sa`n" -ForegroundColor White

Write-Host "🌐 Staging:" -ForegroundColor Cyan
Write-Host "   FQDN: $($staging.fqdn)" -ForegroundColor White
Write-Host "   Image: $($staging.image)" -ForegroundColor Gray
Write-Host "   URL: https://staging.gratech.sa`n" -ForegroundColor White

Write-Host "🔍 اختبار سريع:" -ForegroundColor Yellow
curl.exe -I https://app.gratech.sa
Write-Host ""
curl.exe -I https://staging.gratech.sa

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
