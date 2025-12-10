# =======================================
# PORTAIL CLOUD CONTAINER - DESTROY  
# Version PowerShell pour Windows
# =======================================

$ErrorActionPreference = "Stop"

Write-Host "🗑️  DESTRUCTION DES RESSOURCES AZURE" -ForegroundColor Red
Write-Host "=====================================" -ForegroundColor Red
Write-Host ""

# Vérifier si Terraform est initialisé
if (-not (Test-Path "terraform\azure\.terraform")) {
    Write-Host "[WARNING] Aucune infrastructure Terraform détectée" -ForegroundColor Yellow
    Write-Host "[INFO] Rien à détruire" -ForegroundColor Yellow
    exit 0
}

Set-Location "terraform\azure"

# Afficher les ressources
Write-Host "[INFO] Ressources qui vont être détruites :" -ForegroundColor Yellow
try {
    terraform state list
} catch {
    Write-Host "Impossible de lister les ressources" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "⚠️  ATTENTION: Cette action va DÉFINITIVEMENT détruire toutes les ressources Azure !" -ForegroundColor Red
Write-Host "⚠️  Cette action est IRRÉVERSIBLE !" -ForegroundColor Red
Write-Host ""
Write-Host "Êtes-vous sûr de vouloir continuer ? Tapez 'yes' pour confirmer:" -ForegroundColor Yellow
$confirmation = Read-Host

if ($confirmation -ne "yes") {
    Write-Host "[CANCELLED] Destruction annulée" -ForegroundColor Green
    exit 0
}

Write-Host "[DESTROY] Destruction en cours..." -ForegroundColor Yellow
terraform destroy -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Toutes les ressources ont été détruites !" -ForegroundColor Green
    Write-Host "[INFO] Plus aucun coût Azure ne sera généré" -ForegroundColor Green
    
    # Nettoyer les fichiers
    Remove-Item -Path "tfplan", "terraform.tfstate*", ".terraform.lock.hcl" -Force -ErrorAction SilentlyContinue
    Write-Host "[CLEANUP] Fichiers Terraform nettoyés" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Erreur lors de la destruction" -ForegroundColor Red
    Write-Host "[INFO] Vérifiez manuellement le portail Azure pour les ressources restantes" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✅ Nettoyage terminé avec succès !" -ForegroundColor Green

# Retourner à la racine
Set-Location "..\..\"