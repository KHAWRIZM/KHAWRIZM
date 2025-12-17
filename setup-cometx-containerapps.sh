#!/usr/bin/env bash
# =============================================================
# GrAtech / Comet X — إعداد Azure Container Apps (prod & staging)
# هذا السكربت ينشئ بيئتين وتطبيقين، يفعّل Ingress، يضيف نطاقات مخصصة
# مع شهادات مُدارة (Managed) ويطبع قيم DNS المطلوبة.
# -------------------------------------------------------------
# طريقة الاستخدام:
# 1) عدّل المتغيرات أدناه بما يناسبك.
# 2) شغّل السكربت في Azure Cloud Shell (Bash) أو جهازك المحلي مع Azure CLI.
# 3) أضف سجلات DNS لدى مزودك (CNAME مباشر إلى azurecontainerapps.io).
# 4) راقب حالة الشهادات حتى تصبح Succeeded.
# =============================================================

set -euo pipefail

# =========================
# [0] متغيرات عامة — عدّلها
# =========================
SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"
LOCATION="eastus2"                      # نحترم موقع الـ RG الموجود
RG="<EXISTING_RESOURCE_GROUP_NAME>"     # مثال: rg-cometx-prod

# بيئات Container Apps
ENV_PROD="cae-cometx-prod"
ENV_STG="cae-cometx-staging"

# التطبيقات
APP_PROD="ca-cometx-api"
APP_STG="ca-cometx-api-staging"

# منفذ الخدمة داخل الحاوية
TARGET_PORT=8080                         # عدّل حسب تطبيقك

# صور الحاويات (GHCR مثالاً)
IMAGE_PROD="ghcr.io/<owner>/<repo>:prod"
IMAGE_STG="ghcr.io/<owner>/<repo>:staging"

# النطاقات
DOMAIN_ZONE="gratech.sa"
DOMAIN_PROD="api.${DOMAIN_ZONE}"
DOMAIN_STG="staging.${DOMAIN_ZONE}"

# =========================
# [1] الاشتراك والتحقق من RG
# =========================
az account set --subscription "$SUBSCRIPTION_ID"
echo "== Existing RG details =="
az group show -n "$RG" --query "{name:name, location:location}" -o table

# =========================
# [2] إعداد امتداد Container Apps وتسجيل المزودين
# =========================
az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

# =========================
# [3] إنشاء البيئات (eastus2)
# =========================
az containerapp env create -g "$RG" -n "$ENV_PROD" -l "$LOCATION"
az containerapp env create -g "$RG" -n "$ENV_STG" -l "$LOCATION"

echo "== ENV PROD (domain/ip) =="
az containerapp env show -g "$RG" -n "$ENV_PROD" \
  --query "{defaultDomain:properties.defaultDomain, staticIp:properties.staticIp}" -o json

echo "== ENV STAGING (domain/ip) =="
az containerapp env show -g "$RG" -n "$ENV_STG" \
  --query "{defaultDomain:properties.defaultDomain, staticIp:properties.staticIp}" -o json

# =========================
# [4] إنشاء التطبيقات وتمكين Ingress خارجي
# =========================
az containerapp create -g "$RG" -n "$APP_PROD" \
  --environment "$ENV_PROD" \
  --image "$IMAGE_PROD" \
  --ingress external --target-port $TARGET_PORT

az containerapp create -g "$RG" -n "$APP_STG" \
  --environment "$ENV_STG" \
  --image "$IMAGE_STG" \
  --ingress external --target-port $TARGET_PORT

# =========================
# [5] الحصول على FQDN الافتراضي لكل تطبيق
# =========================
APP_PROD_FQDN=$(az containerapp show -g "$RG" -n "$APP_PROD" --query "properties.configuration.ingress.fqdn" -o tsv)
APP_STG_FQDN=$(az containerapp show -g "$RG" -n "$APP_STG" --query "properties.configuration.ingress.fqdn" -o tsv)

echo "PROD FQDN: $APP_PROD_FQDN"
echo "STG  FQDN: $APP_STG_FQDN"

# =========================
# [6] إضافة النطاقات المخصصة + شهادة Managed
# =========================
az containerapp custom-domain add \
  --name "$APP_PROD" \
  --resource-group "$RG" \
  --domain-name "$DOMAIN_PROD" \
  --environment "$ENV_PROD" \
  --certificate-type Managed

az containerapp custom-domain add \
  --name "$APP_STG" \
  --resource-group "$RG" \
  --domain-name "$DOMAIN_STG" \
  --environment "$ENV_STG" \
  --certificate-type Managed

# =========================
# [7] تعليمات سجلات DNS لدى مزود خارجي
# =========================
echo "==== أضف السجلات لدى مزود DNS الخارجي ===="
echo "CNAME for PROD:    ${DOMAIN_PROD}  ->  ${APP_PROD_FQDN}"
echo "CNAME for STAGING: ${DOMAIN_STG}   ->  ${APP_STG_FQDN}"
echo "\nإن كنت تستخدم CAA على ${DOMAIN_ZONE}:"
echo 'CAA (root): 0 issue "digicert.com"'
echo "تذكير: تجنب أي CNAME وسيط (Cloudflare/Traffic Manager) مع الشهادة المُدارة."

# =========================
# [8] التحقق من حالة الربط والشهادات (poll)
# =========================
function check_status() {
  local app_name=$1
  az containerapp show -g "$RG" -n "$app_name" \
    --query "properties.configuration.ingress.customDomains[].{domain:name,state:validationState,cert:certificateId}" -o table
}

echo "== PROD custom domains (initial) =="
check_status "$APP_PROD"

echo "== STAGING custom domains (initial) =="
check_status "$APP_STG"

# محاولات متتالية للتحقق (كل 30 ثانية × 10)
for i in $(seq 1 10); do
  echo "\n[Attempt ${i}/10] Checking validation state..."
  PROD_STATE=$(az containerapp show -g "$RG" -n "$APP_PROD" --query "properties.configuration.ingress.customDomains[].validationState" -o tsv | head -n1)
  STG_STATE=$(az containerapp show -g "$RG" -n "$APP_STG" --query "properties.configuration.ingress.customDomains[].validationState" -o tsv | head -n1)
  echo "PROD: ${PROD_STATE} | STAGING: ${STG_STATE}"
  if [[ "$PROD_STATE" == "Succeeded" && "$STG_STATE" == "Succeeded" ]]; then
    echo "✅ Certificates issued successfully for both domains."
    break
  fi
  sleep 30
done

echo "== Final status =="
check_status "$APP_PROD"
check_status "$APP_STG"

echo "\nتم — لا تنسَ إنشاء CNAMEs لدى مزودك والانتظار حتى ينتشر DNS بالكامل."
