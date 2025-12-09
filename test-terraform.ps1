# Script de test Terraform local
# Teste l'infrastructure avant le déploiement GitHub Actions

Write-Host "🧪 Test de l'infrastructure Terraform localement" -ForegroundColor Green
Write-Host ""

# Vérifications prérequises
Write-Host "📋 Vérification des prérequis..." -ForegroundColor Yellow

try {
    az --version | Out-Null
    Write-Host "✅ Azure CLI installé" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI manquant. Installez-le d'abord." -ForegroundColor Red
    exit 1
}

try {
    terraform --version | Out-Null
    Write-Host "✅ Terraform installé" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform manquant. Installez-le d'abord." -ForegroundColor Red
    exit 1
}

# Vérification login Azure
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✅ Connecté à Azure: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Non connecté à Azure. Exécutez: az login" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Configuration terraform.tfvars
if (-not (Test-Path "terraform\terraform.tfvars")) {
    Write-Host "📝 Création du fichier terraform.tfvars..." -ForegroundColor Yellow
    Copy-Item "terraform\terraform.tfvars.example" "terraform\terraform.tfvars"
    
    Write-Host ""
    Write-Host "⚠️  Éditez terraform\terraform.tfvars avec vos valeurs:" -ForegroundColor Yellow
    Write-Host "   - admin_password: Mot de passe sécurisé pour PostgreSQL" -ForegroundColor White
    Write-Host "   - project_name: Nom du projet (optionnel)" -ForegroundColor White
    Write-Host "   - location: Région Azure (ex: West Europe)" -ForegroundColor White
    Write-Host ""
    
    # Ouvrir le fichier automatiquement
    Start-Process "terraform\terraform.tfvars"
    
    Write-Host "Appuyez sur Entrée quand vous avez terminé l'édition..." -ForegroundColor Cyan
    Read-Host
}

# Test Terraform
Write-Host "🏗️  Test de l'infrastructure Terraform..." -ForegroundColor Yellow
Set-Location terraform

Write-Host ""
Write-Host "Étape 1: Terraform Init" -ForegroundColor Cyan
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform init a échoué" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Étape 2: Terraform Plan" -ForegroundColor Cyan
terraform plan

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform plan a échoué" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Terraform plan réussi !" -ForegroundColor Green
Write-Host ""

# Option pour appliquer
$apply = Read-Host "Voulez-vous appliquer l'infrastructure maintenant ? (y/N)"
if ($apply -eq "y" -or $apply -eq "Y") {
    Write-Host ""
    Write-Host "🚀 Application de l'infrastructure..." -ForegroundColor Yellow
    terraform apply
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "🎉 Infrastructure déployée avec succès !" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 URLs de l'infrastructure:" -ForegroundColor Cyan
        try {
            $backendUrl = terraform output -raw backend_url
            $frontendUrl = terraform output -raw frontend_url
            $registryUrl = terraform output -raw container_registry_url
            
            Write-Host "   Backend:  $backendUrl" -ForegroundColor White
            Write-Host "   Frontend: $frontendUrl" -ForegroundColor White
            Write-Host "   Registry: $registryUrl" -ForegroundColor White
        } catch {
            Write-Host "   (Outputs non disponibles)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host ""
    Write-Host "✅ Test terminé. Infrastructure NOT déployée." -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 Pour déployer plus tard:" -ForegroundColor Cyan
    Write-Host "   cd terraform" -ForegroundColor White
    Write-Host "   terraform apply" -ForegroundColor White
}

Set-Location ..
Write-Host ""
Write-Host "📚 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "1. Si le test est OK, configurez les secrets GitHub" -ForegroundColor White
Write-Host "2. Pushez sur GitHub pour tester le déploiement automatique" -ForegroundColor White
Write-Host "3. Utilisez .\setup-github-secrets.ps1 pour la configuration" -ForegroundColor White