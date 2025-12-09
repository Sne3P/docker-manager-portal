# Test rapide Azure CLI + Terraform
# Script simple pour valider le setup

Write-Host "🧪 Test complet du setup Azure" -ForegroundColor Green
Write-Host ""

# Test 1: Azure CLI
Write-Host "1. Test Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = az --version 2>$null
    if ($azVersion) {
        Write-Host "   ✅ Azure CLI installé" -ForegroundColor Green
        
        # Test connexion
        try {
            $account = az account show 2>$null | ConvertFrom-Json
            Write-Host "   ✅ Connecté: $($account.user.name)" -ForegroundColor Green
            Write-Host "   📋 Subscription: $($account.name)" -ForegroundColor Cyan
        } catch {
            Write-Host "   ❌ Non connecté à Azure" -ForegroundColor Red
            Write-Host "   💡 Lancez: az login" -ForegroundColor Yellow
            return
        }
    }
} catch {
    Write-Host "   ❌ Azure CLI non trouvé" -ForegroundColor Red
    Write-Host "   💡 Redémarrez PowerShell ou installez: winget install Microsoft.AzureCLI" -ForegroundColor Yellow
    return
}

# Test 2: Terraform
Write-Host ""
Write-Host "2. Test Terraform..." -ForegroundColor Yellow
try {
    terraform --version | Out-Null
    Write-Host "   ✅ Terraform installé" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Terraform non trouvé" -ForegroundColor Red
    Write-Host "   💡 Installez depuis: https://www.terraform.io/downloads" -ForegroundColor Yellow
    return
}

# Test 3: Configuration
Write-Host ""
Write-Host "3. Test configuration..." -ForegroundColor Yellow
if (Test-Path "terraform\terraform.tfvars") {
    Write-Host "   ✅ terraform.tfvars configuré" -ForegroundColor Green
} else {
    Write-Host "   ❌ terraform.tfvars manquant" -ForegroundColor Red
    Write-Host "   💡 Créez le fichier avec admin_password" -ForegroundColor Yellow
    return
}

# Test 4: Terraform init/plan
Write-Host ""
Write-Host "4. Test Terraform..." -ForegroundColor Yellow
Set-Location terraform

Write-Host "   Terraform init..." -ForegroundColor Cyan
terraform init | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Init réussi" -ForegroundColor Green
} else {
    Write-Host "   ❌ Init échoué" -ForegroundColor Red
    Set-Location ..
    return
}

Write-Host "   Terraform plan..." -ForegroundColor Cyan
$planOutput = terraform plan 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Plan réussi" -ForegroundColor Green
    
    # Compter les ressources à créer
    $createCount = ($planOutput | Select-String "will be created").Count
    Write-Host "   📊 $createCount ressources à créer" -ForegroundColor Cyan
} else {
    Write-Host "   ❌ Plan échoué" -ForegroundColor Red
    Write-Host "   Erreur:" -ForegroundColor Red
    $planOutput | Select-String "Error" | ForEach-Object { Write-Host "     $_" -ForegroundColor Red }
    Set-Location ..
    return
}

Set-Location ..

# Résultat final
Write-Host ""
Write-Host "🎉 TOUT FONCTIONNE !" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "1. 💻 Déployer localement: cd terraform && terraform apply" -ForegroundColor White
Write-Host "2. 🌐 Configurer GitHub Actions pour le prof" -ForegroundColor White
Write-Host "3. 🚀 Pousser sur GitHub pour déploiement auto" -ForegroundColor White
Write-Host ""
Write-Host "💡 Le prof pourra forker et déployer automatiquement !" -ForegroundColor Yellow