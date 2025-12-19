#!/usr/bin/env pwsh
# Full Auto Deploy - Build + Update + Test

param(
    [string]$BuildId = "chd",
    [string]$RG = "rg-gratech-comet",
    [string]$App = "cometx-api",
    [string]$ACR = "cometxreg"
)

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 Full Auto Deploy" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# 1️⃣ مراقبة البناء
Write-Host "1️⃣  مراقبة البناء: $BuildId" -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$status = "Running"

while ($status -eq "Running" -and $attempt -lt $maxAttempts) {
    Start-Sleep -Seconds 10
    $attempt++
    $status = az acr task show-run -r $ACR --run-id $BuildId --query "status" -o tsv 2>$null
    Write-Progress -Activity "بناء الصورة" -Status "$status" -PercentComplete ([int](($attempt/$maxAttempts)*100))
}

if ($status -eq "Succeeded") {
    Write-Host "✅ نجح البناء`n" -ForegroundColor Green
} else {
    Write-Host "❌ فشل البناء`n" -ForegroundColor Red
    az acr task logs -r $ACR --run-id $BuildId | Select-String -Pattern "error|failed" -Context 1
    exit 1
}

# 2️⃣ ربط السجل بالهوية
Write-Host "2️⃣  ربط السجل بالهوية المدارة..." -ForegroundColor Yellow
az containerapp registry set -g $RG -n $App --server "${ACR}.azurecr.io" --identity system 2>$null
Write-Host "✅ تم`n" -ForegroundColor Green

# 3️⃣ تأكيد المنفذ
Write-Host "3️⃣  تأكيد المنفذ 8080..." -ForegroundColor Yellow
az containerapp ingress update -g $RG -n $App --target-port 8080 --output none
Write-Host "✅ تم`n" -ForegroundColor Green

# 4️⃣ تحديث الصورة
Write-Host "4️⃣  تحديث الصورة..." -ForegroundColor Yellow
az containerapp update -g $RG -n $App --image "${ACR}.azurecr.io/gratech-cometx:latest" --output none
Write-Host "✅ تم`n" -ForegroundColor Green

# 5️⃣ انتظار التحديث
Write-Host "5️⃣  انتظار التحديث..." -ForegroundColor Yellow
Start-Sleep -Seconds 45

# 6️⃣ فحص الحالة
Write-Host "6️⃣  فحص الحالة..." -ForegroundColor Yellow
$revisions = az containerapp revision list -g $RG -n $App --query "[?properties.active].{name:name,health:properties.healthState,traffic:properties.trafficWeight}" -o json | ConvertFrom-Json

Write-Host "`n📊 المراجعات النشطة:" -ForegroundColor Cyan
foreach ($r in $revisions) {
    $color = if ($r.health -eq "Healthy") { "Green" } else { "Red" }
    Write-Host "   $($r.name): $($r.health) (Traffic: $($r.traffic)%)" -ForegroundColor $color
}

# 7️⃣ اختبار النقاط
Write-Host "`n7️⃣  اختبار النقاط..." -ForegroundColor Yellow
Write-Host "`n🔗 /healthz:" -ForegroundColor Cyan
curl.exe -I https://api.gratech.sa/healthz 2>&1 | Select-String "HTTP"

Write-Host "`n🔗 /:" -ForegroundColor Cyan
curl.exe -I https://api.gratech.sa 2>&1 | Select-String "HTTP"

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ اكتمل!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
