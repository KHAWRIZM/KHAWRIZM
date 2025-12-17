#!/usr/bin/env pwsh
# مراقبة البناء والتحديث التلقائي

param([string]$BuildId = "cha")

Write-Host "`n🔍 مراقبة البناء: $BuildId`n" -ForegroundColor Cyan

$maxAttempts = 40
$attempt = 0
$status = "Running"

while ($status -eq "Running" -and $attempt -lt $maxAttempts) {
    Start-Sleep -Seconds 15
    $attempt++
    $status = az acr task show-run -r cometxreg --run-id $BuildId --query "status" -o tsv 2>$null
    
    $progress = [int](($attempt / $maxAttempts) * 100)
    Write-Progress -Activity "بناء الصورة" -Status "$status - $attempt/$maxAttempts" -PercentComplete $progress
    
    if ($status -eq "Succeeded") {
        Write-Host "`n✅ نجح البناء!`n" -ForegroundColor Green
        
        # تحديث تلقائي
        Write-Host "🔄 تحديث Container App..." -ForegroundColor Yellow
        az containerapp update `
            --name cometx-api `
            --resource-group rg-gratech-comet `
            --image cometxreg.azurecr.io/gratech-cometx:latest `
            --output none
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ تم التحديث بنجاح!`n" -ForegroundColor Green
            Write-Host "🌐 الموقع: https://api.gratech.sa" -ForegroundColor Cyan
            Write-Host "⏳ انتظر 30 ثانية ثم اختبر..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            curl.exe -I https://api.gratech.sa
        }
        break
    }
    elseif ($status -eq "Failed") {
        Write-Host "`n❌ فشل البناء`n" -ForegroundColor Red
        az acr task logs -r cometxreg --run-id $BuildId | Select-String -Pattern "error" -Context 2 | Select-Object -First 10
        break
    }
}

if ($attempt -ge $maxAttempts) {
    Write-Host "`n⚠️ انتهت المحاولات - فحص يدوي مطلوب`n" -ForegroundColor Yellow
}
