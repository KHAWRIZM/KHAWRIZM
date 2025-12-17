# 🚀 سكربت إعداد Git Remote والدفع - نسخة متقدمة
param(
    [string]$RepoOwner = "gratech-sa",
    [string]$RepoName = "gratech-cometx",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Continue"
$RepoUrl = "https://github.com/$RepoOwner/$RepoName.git"

Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 سكربت إعداد GitHub Remote + أول دفع" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# 1️⃣ فحص GitHub CLI
Write-Host "🔍 التحقق من GitHub CLI..." -ForegroundColor Yellow
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghInstalled) {
    Write-Host "❌ GitHub CLI غير مثبت. تثبيته الآن..." -ForegroundColor Red
    Write-Host "   قم بتشغيل: winget install --id GitHub.cli" -ForegroundColor Cyan
    exit 1
}
Write-Host "✅ GitHub CLI موجود`n" -ForegroundColor Green

# 2️⃣ فحص وجود المستودع
Write-Host "🔍 التحقق من وجود المستودع $RepoOwner/$RepoName..." -ForegroundColor Yellow
$repoCheck = gh repo view "$RepoOwner/$RepoName" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  المستودع غير موجود، إنشاؤه الآن..." -ForegroundColor Yellow
    gh repo create "$RepoOwner/$RepoName" --private --confirm
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ تم إنشاء المستودع بنجاح`n" -ForegroundColor Green
        Start-Sleep -Seconds 3
    } else {
        Write-Host "❌ فشل إنشاء المستودع. تحقق من الصلاحيات." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ المستودع موجود`n" -ForegroundColor Green
}

# 3️⃣ إزالة الريموت القديم
Write-Host "🧹 إزالة أي ريموت قديم..." -ForegroundColor Yellow
git remote remove origin 2>$null
Write-Host "✅ تم`n" -ForegroundColor Green

# 4️⃣ إضافة الريموت الجديد
Write-Host "➕ إضافة الريموت: $RepoUrl" -ForegroundColor Green
git remote add origin $RepoUrl
Write-Host ""

# 5️⃣ التحقق من الريموت
Write-Host "📋 الريموتات الحالية:" -ForegroundColor Magenta
git remote -v
Write-Host ""

# 6️⃣ تجهيز الكومت
Write-Host "📦 إضافة الملفات..." -ForegroundColor Blue
git add .

Write-Host "💾 إنشاء كومت..." -ForegroundColor Blue
$commitMsg = "chore: initial deployment setup with OIDC + Container Apps"
git commit -m $commitMsg 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ تم إنشاء الكومت`n" -ForegroundColor Green
} else {
    Write-Host "⚠️  لا توجد تغييرات جديدة للكومت`n" -ForegroundColor Yellow
}

# 7️⃣ الدفع
Write-Host "🚀 دفع الكود إلى $Branch..." -ForegroundColor Green
git push -u origin $Branch

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "🎉 نجح الدفع!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor Green
    
    Write-Host "📍 الخطوات التالية:" -ForegroundColor Cyan
    Write-Host "  1️⃣  تحقق من GitHub Actions: https://github.com/$RepoOwner/$RepoName/actions" -ForegroundColor White
    Write-Host "  2️⃣  أضف Secrets في GitHub Settings > Secrets:" -ForegroundColor White
    Write-Host "      • AZURE_CLIENT_ID" -ForegroundColor Gray
    Write-Host "      • AZURE_TENANT_ID" -ForegroundColor Gray
    Write-Host "      • AZURE_SUBSCRIPTION_ID" -ForegroundColor Gray
    Write-Host "  3️⃣  انتظر اكتمال CI/CD والتحقق من النشر`n" -ForegroundColor White
} else {
    Write-Host "`n❌ فشل الدفع. الأخطاء أعلاه." -ForegroundColor Red
    Write-Host "💡 نصائح:" -ForegroundColor Yellow
    Write-Host "  • تأكد من تسجيل الدخول: gh auth login" -ForegroundColor Gray
    Write-Host "  • تأكد من الصلاحيات على المستودع" -ForegroundColor Gray
    exit 1
}
