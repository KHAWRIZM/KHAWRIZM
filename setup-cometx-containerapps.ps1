# =============================================================
# GrAtech / Comet X — إعداد Azure Container Apps (prod & staging)
# سكربت PowerShell ينشئ بيئتين وتطبيقين، يفعّل Ingress، يضيف نطاقات
# مخصصة بشهادة مُدارة ويطبع قيم DNS المطلوبة.
# -------------------------------------------------------------
# طريقة الاستخدام:
# 1) عدّل المتغيرات أدناه.
# 2) شغّل السكربت من VS Code PowerShell أو Azure Cloud Shell (PowerShell).
# =============================================================

$ErrorActionPreference = 'Stop'

# =========================
# [0] متغيرات عامة — عدّلها
# =========================
$SUBSCRIPTION_ID = '<YOUR_SUBSCRIPTION_ID>'
$LOCATION        = 'eastus2'
$RG              = '<EXISTING_RESOURCE_GROUP_NAME>'  # مثال: rg-cometx-prod

# بيئات Container Apps
$ENV_PROD = 'cae-cometx-prod'
$ENV_STG  = 'cae-cometx-staging'

# التطبيقات
$APP_PROD = 'ca-cometx-api'
$APP_STG  = 'ca-cometx-api-staging'

# منفذ الخدمة داخل الحاوية
$TARGET_PORT = 8080

# صور الحاويات
$IMAGE_PROD = 'ghcr.io/<owner>/<repo>:prod'
$IMAGE_STG  = 'ghcr.io/<owner>/<repo>:staging'

# النطاقات
$DOMAIN_ZONE = 'gratech.sa'
$DOMAIN_PROD = "api.$DOMAIN_ZONE"
$DOMAIN_STG  = "staging.$DOMAIN_ZONE"

# =========================
# [1] الاشتراك والتحقق من RG
# =========================
az account set --subscription $SUBSCRIPTION_ID
Write-Host '== Existing RG details =='
az group show -n $RG --query '{name:name, location:location}' -o table

# =========================
# [2] إعداد امتداد Container Apps وتسجيل المزودين
# =========================
az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

# =========================
# [3] إنشاء البيئات (eastus2)
# =========================
az containerapp env create -g $RG -n $ENV_PROD -l $LOCATION
az containerapp env create -g $RG -n $ENV_STG  -l $LOCATION

Write-Host '== ENV PROD (domain/ip) =='
az containerapp env show -g $RG -n $ENV_PROD --query '{defaultDomain:properties.defaultDomain, staticIp:properties.staticIp}' -o json
Write-Host '== ENV STAGING (domain/ip) =='
az containerapp env show -g $RG -n $ENV_STG  --query '{defaultDomain:properties.defaultDomain, staticIp:properties.staticIp}' -o json

# =========================
# [4] إنشاء التطبيقات وتمكين Ingress خارجي
# =========================
az containerapp create -g $RG -n $APP_PROD --environment $ENV_PROD --image $IMAGE_PROD --ingress external --target-port $TARGET_PORT
az containerapp create -g $RG -n $APP_STG  --environment $ENV_STG  --image $IMAGE_STG  --ingress external --target-port $TARGET_PORT

# =========================
# [5] الحصول على FQDN الافتراضي لكل تطبيق
# =========================
$APP_PROD_FQDN = az containerapp show -g $RG -n $APP_PROD --query 'properties.configuration.ingress.fqdn' -o tsv
$APP_STG_FQDN  = az containerapp show -g $RG -n $APP_STG  --query 'properties.configuration.ingress.fqdn' -o tsv
Write-Host "PROD FQDN: $APP_PROD_FQDN"
Write-Host "STG  FQDN: $APP_STG_FQDN"

# =========================
# [6] إضافة النطاقات المخصصة + شهادة Managed
# =========================
az containerapp custom-domain add --name $APP_PROD --resource-group $RG --domain-name $DOMAIN_PROD --environment $ENV_PROD --certificate-type Managed
az containerapp custom-domain add --name $APP_STG  --resource-group $RG --domain-name $DOMAIN_STG  --environment $ENV_STG  --certificate-type Managed

# =========================
# [7] تعليمات سجلات DNS لدى مزود خارجي
# =========================
Write-Host '==== أضف السجلات لدى مزود DNS الخارجي ===='
Write-Host "CNAME for PROD:    $DOMAIN_PROD  ->  $APP_PROD_FQDN"
Write-Host "CNAME for STAGING: $DOMAIN_STG   ->  $APP_STG_FQDN"
Write-Host "\nإن كنت تستخدم CAA على $DOMAIN_ZONE:"
Write-Host 'CAA (root): 0 issue "digicert.com"'
Write-Host 'تذكير: تجنب أي CNAME وسيط (Cloudflare/Traffic Manager) مع الشهادة المُدارة.'

# =========================
# [8] التحقق من حالة الربط والشهادات (poll)
# =========================
function Show-CustomDomainStatus($AppName) {
  az containerapp show -g $RG -n $AppName --query "properties.configuration.ingress.customDomains[].{domain:name,state:validationState,cert:certificateId}" -o table
}

Write-Host '== PROD custom domains (initial) =='
Show-CustomDomainStatus -AppName $APP_PROD
Write-Host '== STAGING custom domains (initial) =='
Show-CustomDomainStatus -AppName $APP_STG

for ($i = 1; $i -le 10; $i++) {
  Write-Host "`n[Attempt $i/10] Checking validation state..."
  $PROD_STATE = az containerapp show -g $RG -n $APP_PROD --query 'properties.configuration.ingress.customDomains[].validationState' -o tsv | Select-Object -First 1
  $STG_STATE  = az containerapp show -g $RG -n $APP_STG  --query 'properties.configuration.ingress.customDomains[].validationState' -o tsv | Select-Object -First 1
  Write-Host "PROD: $PROD_STATE | STAGING: $STG_STATE"
  if ($PROD_STATE -eq 'Succeeded' -and $STG_STATE -eq 'Succeeded') {
    Write-Host '✅ Certificates issued successfully for both domains.'
    break
  }
  Start-Sleep -Seconds 30
}

Write-Host '== Final status =='
Show-CustomDomainStatus -AppName $APP_PROD
Show-CustomDomainStatus -AppName $APP_STG

Write-Host '\nتم — لا تنسَ إنشاء CNAMEs لدى مزودك والانتظار حتى ينتشر DNS بالكامل.'
