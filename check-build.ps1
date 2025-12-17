#!/usr/bin/env pwsh
# فحص حالة البناء في ACR

param([string]$BuildId = "ch8")

Write-Host "`n🔍 فحص حالة البناء: $BuildId`n" -ForegroundColor Cyan

az acr task logs -r cometxreg --run-id $BuildId --output table

$status = az acr task show-run -r cometxreg --run-id $BuildId --query "status" -o tsv

Write-Host "`n📊 الحالة: " -NoNewline
switch ($status) {
    "Succeeded" { Write-Host "✅ نجح" -ForegroundColor Green }
    "Running"   { Write-Host "⏳ جاري التنفيذ" -ForegroundColor Yellow }
    "Failed"    { Write-Host "❌ فشل" -ForegroundColor Red }
    default     { Write-Host "$status" -ForegroundColor Gray }
}

if ($status -eq "Succeeded") {
    Write-Host "`n🎉 الصورة جاهزة: cometxreg.azurecr.io/gratech-cometx:latest`n" -ForegroundColor Green
    Write-Host "📌 الخطوة التالية: تحديث Container Apps" -ForegroundColor Cyan
    Write-Host "   .\update-container-apps.ps1`n" -ForegroundColor White
}
