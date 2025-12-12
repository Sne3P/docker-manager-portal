# =============================================================
# PORTAIL CLOUD - SCRIPT DE DEPLOIEMENT OPTIMISE POWERSHELL
# =============================================================
param(
    [switch]$Clean,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Continue"
$env:PATH += ";C:\Users\basti\AppData\Local\Temp\terraform"

# Colors
$colors = @{
    Red = "Red"
    Green = "Green" 
    Yellow = "Yellow"
    Cyan = "Cyan"
    White = "White"
    Gray = "Gray"
}

function Log { param($msg) Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $msg" -ForegroundColor $colors.Cyan }
function Success { param($msg) Write-Host "✓ $msg" -ForegroundColor $colors.Green }
function Warn { param($msg) Write-Host "⚠ $msg" -ForegroundColor $colors.Yellow }
function Error { param($msg) Write-Host "❌ $msg" -ForegroundColor $colors.Red; exit 1 }

Log "🚀 DÉPLOIEMENT PORTAIL CLOUD OPTIMISÉ"

# ===========================
# PHASE 0: AUTHENTICATION & SETUP
# ===========================
Log "Phase 0: Configuration initiale"

$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) { 
    Log "Connexion Azure requise..."
    az login 
    $account = az account show --output json | ConvertFrom-Json 
}

$uniqueId = ($account.user.name -replace '[^a-zA-Z0-9]', '').ToLower().Substring(0, 8)
$subscriptionId = $account.id
$rgName = "rg-container-manager-$uniqueId"

Success "ID unique: $uniqueId | Subscription: $subscriptionId"

# ===========================
# PHASE 1: CLEANUP (IF REQUESTED)
# ===========================
if ($Clean) {
    Log "Phase 1: Nettoyage des ressources"
    
    # Delete resource group (async)
    az group delete --name $rgName --yes --no-wait 2>$null | Out-Null
    
    # Clean Terraform state
    Push-Location terraform\azure
    Remove-Item .terraform*, terraform.tfstate*, tfplan* -Recurse -Force -ErrorAction SilentlyContinue
    Pop-Location
    
    Success "Nettoyage lancé (asynchrone)"
    
    # Wait a bit for resources to start deleting
    Log "Attente du nettoyage (60s)..."
    Start-Sleep 60
}

# ===========================
# PHASE 2: INFRASTRUCTURE TERRAFORM
# ===========================
Log "Phase 2: Infrastructure Terraform"

Push-Location terraform\azure

# Initialize Terraform (only if needed)
if (-not (Test-Path ".terraform")) {
    Log "Initialisation Terraform..."
    terraform init -upgrade
}

# Smart conflict resolution
Log "Résolution des conflits d'état..."
if (az group show --name $rgName 2>$null) {
    # Import existing container apps if they exist but aren't in state
    $backendExists = az containerapp show --name "backend-$uniqueId" --resource-group $rgName 2>$null
    $frontendExists = az containerapp show --name "frontend-$uniqueId" --resource-group $rgName 2>$null
    
    $stateList = terraform state list 2>$null
    
    if ($backendExists -and -not ($stateList | Select-String "azurerm_container_app.backend")) {
        Warn "Import backend existant dans l'état Terraform"
        $backendId = ($backendExists | ConvertFrom-Json).id
        terraform import "azurerm_container_app.backend" $backendId 2>$null | Out-Null
    }
    
    if ($frontendExists -and -not ($stateList | Select-String "azurerm_container_app.frontend")) {
        Warn "Import frontend existant dans l'état Terraform"
        $frontendId = ($frontendExists | ConvertFrom-Json).id
        terraform import "azurerm_container_app.frontend" $frontendId 2>$null | Out-Null
    }
}

# Plan and apply in one go
Log "Déploiement infrastructure..."
terraform plan -var="unique_id=$uniqueId" -out=tfplan
terraform apply -auto-approve tfplan

# Get outputs
Log "Récupération des informations Terraform..."
try {
    $outputs = terraform output -json | ConvertFrom-Json
    $acrServer = $outputs.container_registry_login_server.value
    $acrName = $outputs.acr_name.value
    $dbUrl = $outputs.database_url.value
} catch {
    Error "Impossible de récupérer les informations Terraform"
}

Pop-Location

if (-not $acrServer -or -not $acrName) {
    Error "Informations Terraform manquantes"
}

Success "Infrastructure créée: $acrServer"

# ===========================
# PHASE 3: DOCKER IMAGES BUILD & PUSH (ORDRE CRITIQUE)
# ===========================
if (-not $SkipBuild) {
    Log "Phase 3: Construction des images Docker (ordre optimisé)"
    
    # Login to ACR
    az acr login --name $acrName
    
    # ÉTAPE 3A: Build Backend (SANS push - Container Apps pas encore prêts)
    Log "  📦 Backend (build local)..."
    docker build -t "$acrServer/dashboard-backend:latest" ./dashboard-backend
    Success "Backend build terminé (pas encore pushé)"
    
    # ÉTAPE 3B: Vérification DYNAMIQUE que les Container Apps existent
    Log "Vérification que les Container Apps sont créés par Terraform..."
    $containerAppsReady = $false
    $maxWaitAttempts = 20
    $waitAttempt = 0
    
    while ($waitAttempt -lt $maxWaitAttempts -and -not $containerAppsReady) {
        $waitAttempt++
        Log "  Vérification Container Apps $waitAttempt/$maxWaitAttempts..."
        
        # Vérifier existence des deux Container Apps
        $backendExists = az containerapp show --name "backend-$uniqueId" --resource-group $rgName --query "properties.provisioningState" -o tsv 2>$null
        $frontendExists = az containerapp show --name "frontend-$uniqueId" --resource-group $rgName --query "properties.provisioningState" -o tsv 2>$null
        
        if ($backendExists -and $frontendExists -and $backendExists -ne "NotFound" -and $frontendExists -ne "NotFound") {
            if ($backendExists -eq "Succeeded" -and $frontendExists -eq "Succeeded") {
                $containerAppsReady = $true
                Success "✅ Container Apps créés et prêts (Backend: $backendExists, Frontend: $frontendExists)"
            } else {
                Log "    Container Apps en cours de création (Backend: $backendExists, Frontend: $frontendExists)..."
                Start-Sleep 15
            }
        } else {
            Log "    Container Apps pas encore créés, attente 15s..."
            Start-Sleep 15
        }
    }
    
    if (-not $containerAppsReady) {
        Error "❌ TIMEOUT: Container Apps non créés après $maxWaitAttempts tentatives"
        exit 1
    }
    
    # ÉTAPE 3C: Maintenant on peut PUSH le backend en sécurité
    Log "  📤 Push Backend vers ACR (Container Apps prêts)..."
    docker push "$acrServer/dashboard-backend:latest"
    Success "✅ Backend pushé avec succès"
    
    # ÉTAPE 3C: Récupération FIABLE des URLs finales
    Log "Récupération des URLs finales des Container Apps..."
    Push-Location terraform\azure
    
    # Tentative 1: Via Terraform outputs
    try {
        $backendUrl = terraform output -raw backend_url 2>$null
        $frontendUrl = terraform output -raw frontend_url 2>$null
    } catch {
        $backendUrl = ""
        $frontendUrl = ""
    }
    
    Pop-Location
    
    # Tentative 2: Si Terraform outputs vides, utiliser Azure CLI avec retry
    if (-not $backendUrl -or -not $frontendUrl) {
        Warn "URLs Terraform manquantes, récupération via Azure CLI..."
        
        for ($i = 1; $i -le 5; $i++) {
            $backendFqdn = az containerapp show --name "backend-$uniqueId" --resource-group $rgName --query "properties.configuration.ingress.fqdn" -o tsv 2>$null
            $frontendFqdn = az containerapp show --name "frontend-$uniqueId" --resource-group $rgName --query "properties.configuration.ingress.fqdn" -o tsv 2>$null
            
            if ($backendFqdn -and $frontendFqdn) {
                $backendUrl = "https://$backendFqdn"
                $frontendUrl = "https://$frontendFqdn"
                Success "URLs récupérées via Azure CLI (tentative $i)"
                break
            } else {
                Warn "Tentative $i/5 - URLs non disponibles, attente 15s..."
                Start-Sleep 15
            }
        }
    }
    
    # Vérification intelligente des URLs avec retry
    $urlsRetrieved = $false
    $maxUrlAttempts = 10
    $urlAttempt = 0
    
    while ($urlAttempt -lt $maxUrlAttempts -and -not $urlsRetrieved) {
        $urlAttempt++
        Log "  Tentative récupération URLs $urlAttempt/$maxUrlAttempts..."
        
        # Test de connectivité si URLs trouvées
        if ($backendUrl -and $frontendUrl) {
            try {
                $response = Invoke-WebRequest -Uri $backendUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
                $urlsRetrieved = $true
                Success "✅ URLs récupérées et accessibles"
                Success "   Backend: $backendUrl | Frontend: $frontendUrl"
            } catch {
                Log "    URLs trouvées mais pas encore accessibles, attente 20s..."
                Start-Sleep 20
            }
        } else {
            Log "    URLs pas encore disponibles, attente 20s..."
            Start-Sleep 20
        }
    }
    
    # Vérification finale critique
    if (-not $urlsRetrieved -or -not $backendUrl -or -not $frontendUrl) {
        Error "❌ ÉCHEC CRITIQUE: Impossible de récupérer les URLs après $maxUrlAttempts tentatives"
        Warn "   Vérifiez manuellement les Container Apps dans le portail Azure"
        Warn "   Resource Group: $rgName"
        exit 1
    }
    
    # ÉTAPE 3D: Build Frontend avec la bonne API URL
    Log "  📦 Frontend avec API URL correcte: $backendUrl/api"
    docker build --build-arg NEXT_PUBLIC_API_URL="$backendUrl/api" -t "$acrServer/dashboard-frontend:latest" ./dashboard-frontend
    docker push "$acrServer/dashboard-frontend:latest"
    Success "Frontend pushed avec NEXT_PUBLIC_API_URL=$backendUrl/api"
    
    
    # ÉTAPE 3E: Build Images Démo en parallèle (moins critique)
    Log "  📦 Images démo (en parallèle)..."
    $jobs = @()
    
    $jobs += Start-Job -ScriptBlock {
        param($acrServer)
        docker build -t "$acrServer/nodejs-demo:latest" ./docker-images/nodejs-demo
        docker push "$acrServer/nodejs-demo:latest"
    } -ArgumentList $acrServer
    
    $jobs += Start-Job -ScriptBlock {
        param($acrServer)
        docker build -t "$acrServer/python-demo:latest" ./docker-images/python-demo
        docker push "$acrServer/python-demo:latest"
    } -ArgumentList $acrServer
    
    $jobs += Start-Job -ScriptBlock {
        param($acrServer)
        docker build -t "$acrServer/database-demo:latest" ./docker-images/database-demo
        docker push "$acrServer/database-demo:latest"
    } -ArgumentList $acrServer
    
    $jobs += Start-Job -ScriptBlock {
        param($acrServer)
        docker build -t "$acrServer/nginx-demo:latest" ./docker-images/nginx-demo
        docker push "$acrServer/nginx-demo:latest"
    } -ArgumentList $acrServer
    
    # Wait for demo builds to complete
    $jobs | Wait-Job | Remove-Job
    Success "Images démo pushées (parallèlement)"
    
    Success "✅ Toutes les images déployées avec URLs correctes"
} else {
    Log "Phase 3: Construction d'images ignorée (--skip-build)"
    
    # Still get URLs for later use
    Push-Location terraform\azure
    try {
        $backendUrl = terraform output -raw backend_url 2>$null
        $frontendUrl = terraform output -raw frontend_url 2>$null
    } catch {
        $backendUrl = ""
        $frontendUrl = ""
    }
    Pop-Location
}

# ===========================
# PHASE 4: CONTAINER APPS CONFIGURATION
# ===========================
Log "Phase 4: Configuration des Container Apps"

# Configure MSI and permissions for backend
Log "Configuration MSI et permissions..."
az containerapp identity assign --name "backend-$uniqueId" --resource-group $rgName --system-assigned 2>$null | Out-Null

# Attente DYNAMIQUE que l'identité soit propagée
Log "Attente de la propagation de l'identité MSI..."
$msiReady = $false
for ($i = 1; $i -le 12; $i++) {  # Max 2 minutes
    $principalCheck = az containerapp show --name "backend-$uniqueId" --resource-group $rgName --query "identity.principalId" -o tsv 2>$null
    if ($principalCheck -and $principalCheck -ne "null") {
        $msiReady = $true
        Success "MSI propagé (Principal ID: $($principalCheck.Substring(0,8))...)"
        break
    }
    Log "  Attente propagation MSI $i/12 (10s)..."
    Start-Sleep 10
}

if (-not $msiReady) {
    Warn "⚠️ MSI propagation timeout, continuons quand même..."
}

# Get MSI Principal ID and assign permissions
$identityInfo = az containerapp show --name "backend-$uniqueId" --resource-group $rgName --query "identity" 2>$null | ConvertFrom-Json
if ($identityInfo -and $identityInfo.principalId) {
    $principalId = $identityInfo.principalId
    az role assignment create --assignee $principalId --role "Contributor" --scope "/subscriptions/$subscriptionId/resourceGroups/$rgName" 2>$null | Out-Null
    Success "Permissions MSI configurées"
}

# Configure CORS and environment variables if we have URLs
if ($backendUrl -and $frontendUrl) {
    Log "Configuration CORS et variables d'environnement..."
    
    # Update backend with CORS configuration
    az containerapp update --name "backend-$uniqueId" --resource-group $rgName --set-env-vars "FRONTEND_URL=$frontendUrl" 2>$null | Out-Null
    
    # Update frontend with API URL
    az containerapp update --name "frontend-$uniqueId" --resource-group $rgName --set-env-vars "NODE_ENV=production" "NEXT_PUBLIC_API_URL=$backendUrl/api" 2>$null | Out-Null
    
    Success "CORS configuré: Backend ↔ Frontend"
}

# ===========================
# PHASE 5: DATABASE INITIALIZATION
# ===========================
Log "Phase 5: Initialisation de la base de données"

# Wait for backend to be ready
Log "Attente du backend..."
$maxRetries = 20
$retryCount = 0
$backendReady = $false

while ($retryCount -lt $maxRetries -and -not $backendReady) {
    $retryCount++
    Log "  Test de santé $retryCount/$maxRetries..."
    
    if ($backendUrl) {
        try {
            $healthCheck = Invoke-RestMethod "$backendUrl/api/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
            if ($healthCheck.success) {
                $backendReady = $true
                Success "Backend prêt"
            }
        } catch {
            Start-Sleep 10
        }
    } else {
        Start-Sleep 10
    }
}

# Initialize database if backend is ready
if ($backendReady) {
    Log "Initialisation de la base de données..."
    
    for ($i = 1; $i -le 3; $i++) {
        try {
            $dbInit = Invoke-RestMethod "$backendUrl/api/database/init-database" -Method POST -TimeoutSec 30 -ErrorAction Stop
            if ($dbInit.success) {
                Success "Base de données initialisée"
                break
            }
        } catch {
            Warn "Tentative $i/3 échouée, nouvelle tentative dans 10s..."
            if ($i -lt 3) { Start-Sleep 10 }
        }
    }
} else {
    Warn "Backend non accessible, initialisation DB manuelle requise"
}

# ===========================
# PHASE 6: VALIDATION RAPIDE
# ===========================
Log "Phase 6: Validation du déploiement"

$validationSuccess = $true

# Test backend health
if ($backendUrl) {
    Log "Test API backend..."
    try {
        $healthResponse = Invoke-RestMethod "$backendUrl/api/health" -TimeoutSec 10 -ErrorAction Stop
        if ($healthResponse.success) {
            Success "Backend opérationnel"
        } else {
            Warn "Backend non accessible"
            $validationSuccess = $false
        }
    } catch {
        Warn "Backend non accessible"
        $validationSuccess = $false
    }
}

# Test authentication
if ($backendUrl -and $validationSuccess) {
    Log "Test authentification..."
    try {
        $loginBody = @{ email = "admin@portail-cloud.com"; password = "admin123" } | ConvertTo-Json
        $headers = @{ "Content-Type" = "application/json" }
        $authResponse = Invoke-RestMethod "$backendUrl/api/auth/login" -Method POST -Body $loginBody -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        
        if ($authResponse.success) {
            Success "Authentification fonctionnelle"
        } else {
            Warn "Test d'authentification échoué"
            $validationSuccess = $false
        }
    } catch {
        Warn "Test d'authentification échoué"
        $validationSuccess = $false
    }
}

# ===========================
# DEPLOYMENT SUMMARY
# ===========================
Write-Host ""
Write-Host "===============================================" -ForegroundColor $colors.Cyan
Write-Host "🎉 DÉPLOIEMENT TERMINÉ" -ForegroundColor $colors.Cyan
Write-Host "===============================================" -ForegroundColor $colors.Cyan
Write-Host ""
Write-Host "📍 URLs de production:" -ForegroundColor $colors.White
Write-Host "   Frontend: $frontendUrl" -ForegroundColor $colors.Gray
Write-Host "   Backend:  $backendUrl" -ForegroundColor $colors.Gray
Write-Host ""
Write-Host "👥 Utilisateurs de test:" -ForegroundColor $colors.White
Write-Host "   • Admin:    admin@portail-cloud.com / admin123" -ForegroundColor $colors.Gray
Write-Host "   • Client 1: client1@portail-cloud.com / client123" -ForegroundColor $colors.Gray
Write-Host "   • Client 2: client2@portail-cloud.com / client123" -ForegroundColor $colors.Gray
Write-Host "   • Client 3: client3@portail-cloud.com / client123" -ForegroundColor $colors.Gray
Write-Host ""
Write-Host "🔗 Endpoints utiles:" -ForegroundColor $colors.White
Write-Host "   • Santé:        $backendUrl/api/health" -ForegroundColor $colors.Gray
Write-Host "   • Statut DB:    $backendUrl/api/health/db-status" -ForegroundColor $colors.Gray
Write-Host "   • Connexion:    $backendUrl/api/auth/login" -ForegroundColor $colors.Gray
Write-Host "   • Init DB:      $backendUrl/api/database/init-database" -ForegroundColor $colors.Gray
Write-Host ""

if ($validationSuccess) {
    Success "✅ SYSTÈME PLEINEMENT OPÉRATIONNEL!"
    Write-Host ""
    $openBrowser = Read-Host "🌐 Ouvrir le frontend dans le navigateur? [Y/n]"
    if ($openBrowser -ne "n" -and $openBrowser -ne "N" -and $frontendUrl) {
        Start-Process $frontendUrl
        Log "Ouverture du frontend dans le navigateur..."
    }
} else {
    Warn "⚠️ Validation partielle - Vérifiez les logs ci-dessus"
    Write-Host "   Utilisez validate-deployment-clean.ps1 pour une validation complète." -ForegroundColor $colors.Gray
}

Write-Host ""
Success "Deploiement termine en $((Get-Date).ToString('HH:mm:ss'))"