# Comet X — CI/CD على Azure Container Apps (OIDC + GHCR)

## المتطلبات
- Azure Subscription + App Registration مع **Federated Credential (OIDC)**
- أسرار GitHub:
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_CLIENT_ID`
- وجود تطبيقات Container Apps:
  - إنتاج: `ca-cometx-api` في بيئة `cae-cometx-prod`
  - ستيجنج: `ca-cometx-api-staging` في بيئة `cae-cometx-staging`
- ضبط DNS للنطاقات الفرعية (CNAME مباشر إلى `*.azurecontainerapps.io`) وشهادة **Managed** إذا رغبت

## ما الذي يفعله هذا القالب؟
- يبني صورة Docker ويدفعها إلى **GHCR** (ghcr.io/gratech-sa/gratech-cometx:latest)
- يفحص أمن الصورة بـ **Trivy** (يفشل فقط عند **CRITICAL**)
- يسجّل الدخول إلى Azure باستخدام **OIDC** وينشر إلى **Container Apps**
- يفعل **CodeQL** و **Dependabot**

## التخصيص السريع
- عدّل أسماء الموارد داخل `deploy.yml` إذا لزم:
  - `RESOURCE_GROUP`, `APP_PROD`, `APP_STG`
- الفرع `main` ينشر إلى الإنتاج، والفرع `staging` ينشر إلى الستيجنج.

## خطوات DNS للشهادات المُدارة
- أنشئ CNAME لـ `api.gratech.sa` → FQDN تطبيق الإنتاج
- أنشئ CNAME لـ `staging.gratech.sa`  → FQDN تطبيق الستيجنج
- إن كان لديك CAA على الجذر `gratech.sa`، أضف: `0 issue "digicert.com"`

## أوامر تحقق سريعة
```bash
az containerapp show -g rg-cometx-prod -n ca-cometx-api --query "properties.configuration.ingress.fqdn" -o tsv
az containerapp show -g rg-cometx-prod -n ca-cometx-api-staging  --query "properties.configuration.ingress.fqdn" -o tsv
```
