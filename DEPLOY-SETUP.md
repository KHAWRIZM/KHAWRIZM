# 🚀 دليل نشر GraTech CometX على Azure Container Apps

## 📋 المعلومات الأساسية

**معلومات Azure:**
- Subscription ID: `dde8416c-6077-4b2b-b722-05bf8b782c44`
- Tenant ID: `a1cc28df-8965-4e03-96cb-5d6172ff55a5`
- Resource Group: `rg-cometx-prod` (eastus2)

**معلومات GitHub:**
- المنظمة: `gratech-sa`
- المستودع: `gratech-cometx`
- السجل: `ghcr.io/gratech-sa/gratech-cometx`

**النطاقات:**
- إنتاج: `api.gratech.sa`
- تجريبي: `staging.gratech.sa`

**Container Apps:**
- Prod: `ca-cometx-api` في بيئة `cae-cometx-prod`
- Staging: `ca-cometx-api-staging` في بيئة `cae-cometx-staging`

---

## 1️⃣ إنشاء OIDC للمصادقة الآمنة

شغّل السكربت لإنشاء **App Registration** و **Federated Credentials**:

```powershell
.\create-azure-oidc.ps1
```

**النتيجة:** سيعطيك ثلاث قيم لإضافتها في **GitHub Secrets**:
```
AZURE_CLIENT_ID = 9036905f-24d2-4f5e-99e7-98b8638b5abe
AZURE_TENANT_ID = a1cc28df-8965-4e03-96cb-5d6172ff55a5
AZURE_SUBSCRIPTION_ID = dde8416c-6077-4b2b-b722-05bf8b782c44
```

### إضافة Secrets في GitHub:
1. افتح: `https://github.com/gratech-sa/gratech-cometx/settings/secrets/actions`
2. اضغط **New repository secret**
3. أضف الثلاث قيم أعلاه

---

## 2️⃣ إنشاء Container Apps والنطاقات

### الطريقة الأولى: PowerShell
```powershell
.\setup-cometx-containerapps.ps1
```

### الطريقة الثانية: Bash
```bash
chmod +x setup-cometx-containerapps.sh
./setup-cometx-containerapps.sh
```

**ماذا يفعل السكربت؟**
- ✅ إنشاء بيئتين: prod و staging
- ✅ إنشاء تطبيقين مع **external ingress** على منفذ `5173` (Vite)
- ✅ إضافة النطاقات المخصصة (`api.gratech.sa` و `staging.gratech.sa`)
- ✅ تفعيل **Managed Certificates** (SSL مجاني من Azure)
- ✅ طباعة FQDN لكل تطبيق

---

## 3️⃣ إعداد DNS

بعد تشغيل السكربت، سيعطيك **CNAME** لكل بيئة. اذهب لمزود DNS الخاص بـ `gratech.sa` وأضف:

### إنتاج (Production):
```
Type: CNAME
Name: api
Value: ca-cometx-api.victoriousrock-b243cc39.eastus2.azurecontainerapps.io
TTL: 3600
```

### تجريبي (Staging):
```
Type: CNAME
Name: staging
Value: [FQDN من نتيجة السكربت]
TTL: 3600
```

### CAA Record (إذا لزم):
```
Type: CAA
Name: @
Value: 0 issue "digicert.com"
```

> ⚠️ **مهم:** DNS يحتاج 5-60 دقيقة للتفعيل. تحقق بـ:
> ```bash
> nslookup api.gratech.sa
> ```

---

## 4️⃣ أول نشر تلقائي

بعد إضافة GitHub Secrets و DNS:

```bash
git add .
git commit -m "feat: Azure Container Apps CI/CD with OIDC"
git push origin main
```

**النتيجة:**
- ✅ يبني Docker Image
- ✅ يفحص Trivy (يفشل فقط عند **CRITICAL**)
- ✅ يدفع لـ GHCR (`ghcr.io/gratech-sa/gratech-cometx:latest`)
- ✅ يسجل دخول Azure عبر **OIDC** (بدون أسرار!)
- ✅ ينشر على `ca-cometx-api` (production)

### نشر Staging:
```bash
git checkout -b staging
git push origin staging
```
سينشر تلقائيًا على `ca-cometx-api-staging`.

---

## 5️⃣ المراقبة والتحقق

### عرض Container App:
```bash
az containerapp show -g rg-cometx-prod -n ca-cometx-api
```

### عرض السجلات:
```bash
az containerapp logs show -g rg-cometx-prod -n ca-cometx-api --follow
```

### التحقق من الشهادة:
```bash
az containerapp hostname list -g rg-cometx-prod -n ca-cometx-api
```

### اختبار التطبيق:
```bash
curl https://api.gratech.sa
```

---

## 🔧 استكشاف الأخطاء

### مشكلة: فشل Managed Certificate
**السبب:** CNAME غير صحيح أو غير مباشر (عبر Cloudflare مثلاً)

**الحل:**
1. تأكد أن CNAME يشير **مباشرةً** لـ `*.azurecontainerapps.io`
2. إذا كنت تستخدم Cloudflare، عطّل **Proxy (🌥️)** واتركه **DNS only**
3. أضف CAA record: `0 issue "digicert.com"`

### مشكلة: OIDC Login Failed
**الحل:**
- تأكد أن GitHub Secrets مضبوطة بشكل صحيح
- تحقق من Federated Credentials في Azure Portal:
  ```
  issuer: https://token.actions.githubusercontent.com
  subject: repo:gratech-sa/gratech-cometx:ref:refs/heads/main
  ```

### مشكلة: Trivy يفشل الـ Build
**الحل:**
- راجع تقرير Trivy في GitHub Actions
- إذا كانت ثغرات **HIGH** فقط، الـ workflow سيكمل (نحن نفشل فقط عند **CRITICAL**)
- حدّث الـ base image في `Dockerfile`

---

## 📚 الملفات المهمة

| الملف | الوصف |
|-------|-------|
| `.github/workflows/deploy.yml` | CI/CD Pipeline الرئيسي |
| `setup-cometx-containerapps.ps1` | سكربت إنشاء البنية التحتية (PowerShell) |
| `setup-cometx-containerapps.sh` | سكربت إنشاء البنية التحتية (Bash) |
| `create-azure-oidc.ps1` | سكربت إنشاء OIDC |
| `Dockerfile` | بناء الصورة |
| `docs/COMETX-briefing-for-claude.md` | توثيق للـ AI Assistants |

---

## ✅ قائمة التحقق النهائية

- [ ] تشغيل `create-azure-oidc.ps1` وإضافة Secrets في GitHub
- [ ] تشغيل `setup-cometx-containerapps.ps1` أو `.sh`
- [ ] إضافة CNAME records في DNS provider
- [ ] انتظار DNS propagation (5-60 دقيقة)
- [ ] Push إلى `main` لتشغيل أول deployment
- [ ] التحقق من URL: `https://api.gratech.sa`
- [ ] مراجعة السجلات في Azure Portal أو CLI

---

🎉 **مبروك! تطبيقك جاهز على Azure Container Apps مع CI/CD كامل!**
