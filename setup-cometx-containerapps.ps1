$ErrorActionPreference = 'Stop'
$SUBSCRIPTION_ID = 'dde8416c-6077-4b2b-b722-05bf8b782c44'
$LOCATION        = 'eastus2'
$RG              = 'rg-cometx-prod'
$ENV             = 'cometx-env'  # استخدام البيئة الموجودة
$APP_PROD        = 'ca-cometx-api'
$APP_STG         = 'ca-cometx-api-staging'
$TARGET_PORT     = 5173
$IMAGE_PROD      = 'ghcr.io/gratech-sa/gratech-cometx:latest'
$IMAGE_STG       = 'ghcr.io/gratech-sa/gratech-cometx:staging'
$DOMAIN_ZONE     = 'gratech.sa'
$DOMAIN_PROD     = 'api.gratech.sa'
$DOMAIN_STG      = 'staging.gratech.sa'

az account set --subscription $SUBSCRIPTION_ID
az extension add --name containerapp --upgrade

# استخدام البيئة الموجودة فقط
Write-Host "✅ استخدام البيئة الموجودة: $ENV" -ForegroundColor Green

# تحديث التطبيق الموجود أو إنشاء staging
Write-Host "`n📦 تحديث/إنشاء التطبيقات..." -ForegroundColor Cyan
try {
    az containerapp show -g $RG -n $APP_PROD -o none 2>$null
    Write-Host "✓ $APP_PROD موجود - سيتم تحديثه" -ForegroundColor Yellow
    az containerapp update -g $RG -n $APP_PROD --image $IMAGE_PROD
} catch {
    Write-Host "✓ إنشاء $APP_PROD" -ForegroundColor Green
    az containerapp create -g $RG -n $APP_PROD --environment $ENV --image $IMAGE_PROD --ingress external --target-port $TARGET_PORT
}

try {
    az containerapp show -g $RG -n $APP_STG -o none 2>$null
    Write-Host "✓ $APP_STG موجود - سيتم تحديثه" -ForegroundColor Yellow
    az containerapp update -g $RG -n $APP_STG --image $IMAGE_STG
} catch {
    Write-Host "✓ إنشاء $APP_STG" -ForegroundColor Green
    az containerapp create -g $RG -n $APP_STG --environment $ENV --image $IMAGE_STG --ingress external --target-port $TARGET_PORT
}


$APP_PROD_FQDN = az containerapp show -g $RG -n $APP_PROD --query 'properties.configuration.ingress.fqdn' -o tsv
$APP_STG_FQDN  = az containerapp show -g $RG -n $APP_STG  --query 'properties.configuration.ingress.fqdn' -o tsv

Write-Host "`n═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  📋 معلومات DNS:" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "CNAME api.gratech.sa -> $APP_PROD_FQDN" -ForegroundColor Green
Write-Host "CNAME staging.gratech.sa -> $APP_STG_FQDN" -ForegroundColor Green
Write-Host 'CAA (root): 0 issue "digicert.com"' -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`n🔒 إضافة النطاقات المخصصة مع Managed Certificates..." -ForegroundColor Cyan
az containerapp hostname add --hostname $DOMAIN_PROD -g $RG -n $APP_PROD
az containerapp hostname bind --hostname $DOMAIN_PROD -g $RG -n $APP_PROD --environment $ENV --validation-method CNAME
az containerapp hostname add --hostname $DOMAIN_STG -g $RG -n $APP_STG
az containerapp hostname bind --hostname $DOMAIN_STG -g $RG -n $APP_STG --environment $ENV --validation-method CNAME

Write-Host "`n✅ تم! راجع التطبيقات:" -ForegroundColor Green
Write-Host "   Production:  https://$APP_PROD_FQDN" -ForegroundColor White
Write-Host "   Staging:     https://$APP_STG_FQDN" -ForegroundColor White
Write-Host "   Custom Prod: https://$DOMAIN_PROD (بعد DNS)" -ForegroundColor White
Write-Host "   Custom Stg:  https://$DOMAIN_STG (بعد DNS)" -ForegroundColor White
