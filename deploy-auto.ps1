# Script de déploiement automatique pour le Portail Cloud Container
# Usage: .\deploy-auto.ps1 [unique_id]

param(
    [string]$UniqueId = $env:USERNAME
)

$ErrorActionPreference = "Stop"

$ResourceGroup = "rg-container-manager-${UniqueId}"
$AcrName = "acr${UniqueId}"

Write-Host "🚀 Déploiement automatique Portail Cloud Container" -ForegroundColor Green
Write-Host "📋 ID unique: ${UniqueId}"

try {
    # 1. Build et push des images Docker
    Write-Host "🐳 Build et push des images Docker..." -ForegroundColor Yellow

    # Login Azure Container Registry
    az acr login --name $AcrName

    # Build backend avec les dernières corrections
    Write-Host "Building backend image..."
    docker build -t "${AcrName}.azurecr.io/container-manager-backend:real-azure-msi" ./dashboard-backend
    docker push "${AcrName}.azurecr.io/container-manager-backend:real-azure-msi"

    # Build frontend avec configuration API correcte  
    Write-Host "Building frontend image..."
    docker build -t "${AcrName}.azurecr.io/dashboard-frontend:api-fixed" ./dashboard-frontend
    docker push "${AcrName}.azurecr.io/dashboard-frontend:api-fixed"

    Write-Host "✅ Images Docker déployées" -ForegroundColor Green

    # 2. Déploiement Terraform
    Write-Host "🏗️ Déploiement Terraform..." -ForegroundColor Yellow
    Set-Location "terraform\azure"

    # Initialisation (si nécessaire)
    terraform init

    # Planification
    terraform plan -var="unique_id=${UniqueId}" -out=tfplan

    # Application
    terraform apply tfplan

    Write-Host "✅ Infrastructure déployée" -ForegroundColor Green

    # 3. Récupération des URLs
    Write-Host "🌐 URLs de l'application:" -ForegroundColor Cyan
    $BackendUrl = terraform output -raw backend_url
    $FrontendUrl = terraform output -raw frontend_url

    Write-Host "Backend:  $BackendUrl" -ForegroundColor White
    Write-Host "Frontend: $FrontendUrl" -ForegroundColor White

    # 4. Test de connectivité
    Write-Host "🧪 Test de connectivité..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri "$BackendUrl/health" -Method GET
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Backend accessible" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Backend non accessible: $_" -ForegroundColor Red
    }

    try {
        $response = Invoke-WebRequest -Uri $FrontendUrl -Method GET
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Frontend accessible" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Frontend non accessible: $_" -ForegroundColor Red
    }

    Write-Host "🎉 Déploiement terminé !" -ForegroundColor Green

} catch {
    Write-Host "❌ Erreur during deployment: $_" -ForegroundColor Red
    exit 1
} finally {
    # Retour au répertoire racine
    Set-Location "../.."
}