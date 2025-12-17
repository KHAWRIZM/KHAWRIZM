#!/usr/bin/env pwsh
# ═══════════════════════════════════════════════════════════════
# 🔧 Fix GitHub Push - تصليح الدفع لـ GitHub
# ═══════════════════════════════════════════════════════════════

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 Fix GitHub Push Script" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ────────────────────────────────────────────────────────────────
# 1️⃣ Check if GitHub CLI is installed
# ────────────────────────────────────────────────────────────────
Write-Host "1️⃣  Checking GitHub CLI..." -ForegroundColor Yellow
$ghExists = Get-Command gh -ErrorAction SilentlyContinue

if (-not $ghExists) {
    Write-Host "⚠️  GitHub CLI not installed" -ForegroundColor Red
    Write-Host "   Installing via winget..." -ForegroundColor Yellow
    winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements
    Write-Host "✅ GitHub CLI installed" -ForegroundColor Green
} else {
    Write-Host "✅ GitHub CLI already installed" -ForegroundColor Green
}

# ────────────────────────────────────────────────────────────────
# 2️⃣ Check GitHub authentication
# ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "2️⃣  Checking GitHub authentication..." -ForegroundColor Yellow
$authStatus = gh auth status 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Not logged in to GitHub" -ForegroundColor Red
    Write-Host "   Launching browser for authentication..." -ForegroundColor Yellow
    gh auth login --web --git-protocol https
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Successfully authenticated" -ForegroundColor Green
    } else {
        Write-Host "❌ Authentication failed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Already authenticated" -ForegroundColor Green
}

# ────────────────────────────────────────────────────────────────
# 3️⃣ Check if repository exists
# ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "3️⃣  Checking if repository exists..." -ForegroundColor Yellow
$repoExists = gh repo view gratech-sa/gratech-cometx 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Repository does not exist" -ForegroundColor Red
    Write-Host "   Creating repository..." -ForegroundColor Yellow
    
    gh repo create gratech-sa/gratech-cometx `
        --private `
        --description "CometX - AI-Powered Development Platform" `
        --confirm
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Repository created" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create repository" -ForegroundColor Red
        Write-Host "   You may need to create it manually at:" -ForegroundColor Yellow
        Write-Host "   https://github.com/organizations/gratech-sa/repositories/new" -ForegroundColor Cyan
        exit 1
    }
} else {
    Write-Host "✅ Repository exists" -ForegroundColor Green
}

# ────────────────────────────────────────────────────────────────
# 4️⃣ Fix remote URL (remove trailing slash if exists)
# ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "4️⃣  Fixing remote URL..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin https://github.com/gratech-sa/gratech-cometx.git
Write-Host "✅ Remote URL fixed" -ForegroundColor Green

# ────────────────────────────────────────────────────────────────
# 5️⃣ Push to GitHub
# ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "5️⃣  Pushing to GitHub..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Successfully pushed to GitHub" -ForegroundColor Green
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🎉 Success! GitHub Actions will now:" -ForegroundColor Green
    Write-Host "   • Build Docker image" -ForegroundColor White
    Write-Host "   • Run Trivy security scan" -ForegroundColor White
    Write-Host "   • Deploy to Container Apps" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Monitor progress at:" -ForegroundColor Yellow
    Write-Host "   https://github.com/gratech-sa/gratech-cometx/actions" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed to push" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Possible issues:" -ForegroundColor Yellow
    Write-Host "   1. Wrong branch name (try 'git branch' to check)" -ForegroundColor White
    Write-Host "   2. Permission denied (check GitHub token scopes)" -ForegroundColor White
    Write-Host "   3. Authentication expired (run 'gh auth refresh')" -ForegroundColor White
    exit 1
}
