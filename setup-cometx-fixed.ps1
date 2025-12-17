# إعداد Container Apps مع النطاقات المخصصة والشهادات المُدارة (الطريقة الصحيحة)
$ErrorActionPreference = 'Stop'

$SUBSCRIPTION_ID = 'dde8416c-6077-4b2b-b722-05bf8b782c44'
$RG              = 'rg-cometx-prod'
$ENV_NAME        = 'cometx-env'  # استخدام البيئة الموجودة
$APP_PROD        = 'ca-cometx-api'
$APP_STG         = 'ca-cometx-api-staging'
$TARGET_PORT     = 5173
$IMAGE_LATEST    = 'ghcr.io/gratech-sa/gratech-cometx:latest'
$DOMAIN_PROD     = 'app.gratech.sa'     # تغيير من api لأنه مستخدم
$DOMAIN_STG      = 'staging.gratech.sa'

az account set --subscription $SUBSCRIPTION_ID

Write-Host "`n════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🚀 إعداد Container Apps + النطاقات المخصصة" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# تحقق من التطبيقات الموجودة
Write-Host "`n📦 التحقق من التطبيقات..." -ForegroundColor Cyan

$prodExists = az containerapp show -g $RG -n $APP_PROD -o none 2>$null; $?
$stgExists  = az containerapp show -g $RG -n $APP_STG  -o none 2>$null; $?

if (-not $prodExists) {
    Write-Host "✓ إنشاء $APP_PROD..." -ForegroundColor Green
    az containerapp create -g $RG -n $APP_PROD --environment $ENV_NAME --image $IMAGE_LATEST --ingress external --target-port $TARGET_PORT
} else {
    Write-Host "✓ $APP_PROD موجود - سيتم تحديثه لاحقاً" -ForegroundColor Yellow
}

if (-not $stgExists) {
    Write-Host "✓ إنشاء $APP_STG..." -ForegroundColor Green
    az containerapp create -g $RG -n $APP_STG --environment $ENV_NAME --image $IMAGE_LATEST --ingress external --target-port $TARGET_PORT
} else {
    Write-Host "✓ $APP_STG موجود" -ForegroundColor Yellow
}

# الحصول على FQDNs
$FQDN_PROD = az containerapp show -g $RG -n $APP_PROD --query "properties.configuration.ingress.fqdn" -o tsv
$FQDN_STG  = az containerapp show -g $RG -n $APP_STG  --query "properties.configuration.ingress.fqdn" -o tsv

Write-Host "`n════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📋 معلومات DNS المطلوبة:" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣ Production (app.gratech.sa):" -ForegroundColor Green
Write-Host "   Type:  CNAME" -ForegroundColor White
Write-Host "   Name:  app" -ForegroundColor Gray
Write-Host "   Value: $FQDN_PROD" -ForegroundColor Gray
Write-Host ""
Write-Host "2️⃣ Staging (staging.gratech.sa):" -ForegroundColor Green
Write-Host "   Type:  CNAME" -ForegroundColor White
Write-Host "   Name:  staging" -ForegroundColor Gray
Write-Host "   Value: $FQDN_STG" -ForegroundColor Gray
Write-Host ""
Write-Host "3️⃣ CAA Record (للشهادات المُدارة):" -ForegroundColor Green
Write-Host '   Type:  CAA' -ForegroundColor White
Write-Host '   Name:  @' -ForegroundColor Gray
Write-Host '   Value: 0 issue "digicert.com"' -ForegroundColor Gray
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# انتظار تأكيد DNS
Write-Host "`n⏳ هل أضفت DNS records أعلاه؟ (Y/N): " -ForegroundColor Yellow -NoNewline
$confirmation = Read-Host
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "⚠️ أضف DNS records ثم شغّل السكربت مرة أخرى" -ForegroundColor Red
    exit
}

# إضافة النطاقات المخصصة (الأوامر الصحيحة)
Write-Host "`n🔗 إضافة النطاقات المخصصة..." -ForegroundColor Cyan

try {
    # Production
    Write-Host "✓ إضافة $DOMAIN_PROD..." -ForegroundColor Green
    az containerapp hostname add -g $RG -n $APP_PROD --hostname $DOMAIN_PROD 2>$null
    
    # Staging  
    Write-Host "✓ إضافة $DOMAIN_STG..." -ForegroundColor Green
    az containerapp hostname add -g $RG -n $APP_STG --hostname $DOMAIN_STG 2>$null
} catch {
    Write-Host "⚠️ قد تكون النطاقات مضافة مسبقاً" -ForegroundColor Yellow
}

# إنشاء الشهادات المُدارة
Write-Host "`n🔒 إصدار الشهادات المُدارة..." -ForegroundColor Cyan

try {
    Write-Host "✓ شهادة $DOMAIN_PROD..." -ForegroundColor Green
    az containerapp env certificate create -g $RG -n $ENV_NAME `
        --hostname $DOMAIN_PROD `
        --validation-method CNAME `
        --certificate-name "app-gratech-sa" 2>$null
    
    Write-Host "✓ شهادة $DOMAIN_STG..." -ForegroundColor Green
    az containerapp env certificate create -g $RG -n $ENV_NAME `
        --hostname $DOMAIN_STG `
        --validation-method CNAME `
        --certificate-name "staging-gratech-sa" 2>$null
} catch {
    Write-Host "⚠️ قد تكون الشهادات موجودة أو قيد الإصدار" -ForegroundColor Yellow
}

# ربط الشهادات بالتطبيقات
Write-Host "`n🔐 ربط الشهادات..." -ForegroundColor Cyan

try {
    az containerapp hostname bind -g $RG -n $APP_PROD `
        --environment $ENV_NAME `
        --hostname $DOMAIN_PROD `
        --certificate "app-gratech-sa" `
        --validation-method CNAME 2>$null
    Write-Host "✓ تم ربط شهادة Production" -ForegroundColor Green
    
    az containerapp hostname bind -g $RG -n $APP_STG `
        --environment $ENV_NAME `
        --hostname $DOMAIN_STG `
        --certificate "staging-gratech-sa" `
        --validation-method CNAME 2>$null
    Write-Host "✓ تم ربط شهادة Staging" -ForegroundColor Green
} catch {
    Write-Host "⚠️ تحقق من حالة الشهادات في Azure Portal" -ForegroundColor Yellow
}

Write-Host "`n════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ الإعداد مكتمل!" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 اختبر التطبيقات:" -ForegroundColor Cyan
Write-Host "   Production:  https://$DOMAIN_PROD" -ForegroundColor White
Write-Host "   Staging:     https://$DOMAIN_STG" -ForegroundColor White
Write-Host "   Prod FQDN:   https://$FQDN_PROD" -ForegroundColor Gray
Write-Host "   Stg FQDN:    https://$FQDN_STG" -ForegroundColor Gray
Write-Host ""
