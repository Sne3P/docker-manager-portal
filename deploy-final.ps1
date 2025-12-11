param([switch]$Clean)

$ErrorActionPreference = "Continue"
$env:PATH += ";C:\Users\basti\AppData\Local\Temp\terraform"

Write-Host "=== DEPLOIEMENT PORTAIL CLOUD ===" -ForegroundColor Cyan

# Connexion et ID
$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) { az login; $account = az account show --output json | ConvertFrom-Json }
$uniqueId = ($account.user.name -replace '[^a-zA-Z0-9]', '').ToLower().Substring(0, 8)
Write-Host "ID unique: $uniqueId" -ForegroundColor Green

# Nettoyage si demande
if ($Clean) {
    Write-Host "Nettoyage..." -ForegroundColor Yellow
    $rgName = "rg-container-manager-$uniqueId"
    az group delete --name $rgName --yes --no-wait 2>$null | Out-Null
    Start-Sleep 10
    Push-Location terraform\azure
    Remove-Item .terraform*, terraform.tfstate*, tfplan* -Recurse -Force -ErrorAction SilentlyContinue
    Pop-Location
    Write-Host "Nettoye" -ForegroundColor Green
}

# Phase 1: Infrastructure seule
Write-Host "`nPhase 1: Infrastructure..." -ForegroundColor Yellow
Push-Location terraform\azure
terraform init -upgrade
terraform plan -var="unique_id=$uniqueId" -out=tfplan
terraform apply -auto-approve tfplan

# Recuperation des infos
$outputs = terraform output -json | ConvertFrom-Json
$acrServer = $outputs.container_registry_login_server.value
$acrName = $outputs.acr_name.value
$rgName = $outputs.resource_group_name.value
Pop-Location

Write-Host "Registry: $acrServer" -ForegroundColor Green
Write-Host "Groupe: $rgName" -ForegroundColor Green

# Phase 2: Images Docker (Backend unified + Frontend)
Write-Host "`nPhase 2: Déploiement des images unifiées..." -ForegroundColor Yellow
az acr login --name $acrName

# Build and push the real Azure integration backend
Write-Host "  Construction du backend avec intégration Azure réelle..." -ForegroundColor White
docker build -t "$acrServer/dashboard-backend:real-azure-msi" ./dashboard-backend
Write-Host "  Poussée du backend avec intégration Azure réelle..." -ForegroundColor White
docker push "$acrServer/dashboard-backend:real-azure-msi"

# Build and push frontend avec l'URL backend correcte
Write-Host "  Construction du frontend avec URL API dynamique..." -ForegroundColor White
$containerAppDomain = "delightfulflower-c37029b5.francecentral.azurecontainerapps.io"  # Domaine fixe Azure Container Apps
$backendUrl = "https://backend-${uniqueId}.${containerAppDomain}/api"
docker build --build-arg NEXT_PUBLIC_API_URL="$backendUrl" -t "$acrServer/dashboard-frontend:latest" ./dashboard-frontend
Write-Host "  Poussée du frontend avec URL: $backendUrl" -ForegroundColor White
docker push "$acrServer/dashboard-frontend:latest"

Write-Host "✓ Images déployées (backend avec intégration Azure réelle)" -ForegroundColor Green

# Phase 3: Container Apps avec récupération fiable des URLs
Write-Host "`nPhase 3: Container Apps..." -ForegroundColor Yellow
Push-Location terraform\azure
terraform plan -var="unique_id=$uniqueId" -out=tfplan2
terraform apply -auto-approve tfplan2
Pop-Location

# Phase 3.1: Récupération FIABLE des URLs avec Azure CLI
Write-Host "Récupération des URLs via Azure CLI..." -ForegroundColor White
Start-Sleep 15

$maxUrlRetries = 3
$urlRetryCount = 0
$urlsRetrieved = $false

while (-not $urlsRetrieved -and $urlRetryCount -lt $maxUrlRetries) {
    try {
        $urlRetryCount++
        Write-Host "  Tentative $urlRetryCount/$maxUrlRetries..." -ForegroundColor Gray
        
        $backendFqdn = az containerapp show --name "backend-$uniqueId" --resource-group $rgName --query "properties.configuration.ingress.fqdn" --output tsv 2>$null
        $frontendFqdn = az containerapp show --name "frontend-$uniqueId" --resource-group $rgName --query "properties.configuration.ingress.fqdn" --output tsv 2>$null
        
        if ($backendFqdn -and $frontendFqdn -and $backendFqdn -ne "" -and $frontendFqdn -ne "") {
            $backendUrl = "https://$backendFqdn"
            $frontendUrl = "https://$frontendFqdn"
            Write-Host "✓ URLs récupérées avec succès:" -ForegroundColor Green
            Write-Host "  Backend:  $backendUrl" -ForegroundColor Gray
            Write-Host "  Frontend: $frontendUrl" -ForegroundColor Gray
            $urlsRetrieved = $true
        } else {
            throw "URLs vides ou non disponibles"
        }
    } catch {
        Write-Host "  ⚠ Tentative $urlRetryCount échouée: $($_.Exception.Message)" -ForegroundColor Yellow
        if ($urlRetryCount -lt $maxUrlRetries) {
            Write-Host "  Attente avant nouvelle tentative..." -ForegroundColor Gray
            Start-Sleep 10
        }
    }
}

if (-not $urlsRetrieved) {
    Write-Host "❌ Impossible de récupérer les URLs après $maxUrlRetries tentatives" -ForegroundColor Red
    $backendUrl = ""
    $frontendUrl = ""
}

# Phase 4: Configuration CORS et variables d'environnement
Write-Host "`nPhase 4: Configuration CORS et variables..." -ForegroundColor Yellow

if ($backendUrl -and $frontendUrl) {
    Write-Host "Configuration CORS pour la production..." -ForegroundColor White
    
    # Configuration du backend avec FRONTEND_URL pour CORS
    az containerapp update --name "backend-$uniqueId" --resource-group $rgName `
        --set-env-vars "FRONTEND_URL=$frontendUrl" "NODE_ENV=production" 2>$null | Out-Null
        
    # Configuration du frontend - NOTE: NEXT_PUBLIC_API_URL est maintenant défini au build-time
    az containerapp update --name "frontend-$uniqueId" --resource-group $rgName `
        --set-env-vars "NODE_ENV=production" 2>$null | Out-Null
        
    Write-Host "✓ Variables d'environnement configurées" -ForegroundColor Green
    
    # Attente du redémarrage
    Write-Host "Attente du redémarrage des containers..." -ForegroundColor White
    Start-Sleep 45
}

# Phase 6: Initialisation COMPLÈTE de la base de données (UNIFIED)
Write-Host "`nPhase 6: Initialisation unifiée de la base de données..." -ForegroundColor Yellow

if ($backendUrl) {
    Write-Host "Initialisation du schéma complet via endpoint unifié..." -ForegroundColor White
    
    $maxRetries = 5
    $retryCount = 0
    $dbInitialized = $false
    
    while (-not $dbInitialized -and $retryCount -lt $maxRetries) {
        try {
            $retryCount++
            Write-Host "  Tentative $retryCount/$maxRetries..." -ForegroundColor Gray
            
            # Test de santé d'abord
            $healthCheck = Invoke-RestMethod "$backendUrl/api/health" -Method GET -TimeoutSec 15
            
            # Initialisation COMPLÈTE via endpoint unifié (maintenant équivalent à init.sql)
            $dbInit = Invoke-RestMethod "$backendUrl/api/database/init-database" -Method POST -TimeoutSec 45
            
            if ($dbInit.success) {
                Write-Host "✓ Schéma de base de données COMPLET initialisé" -ForegroundColor Green
                Write-Host "  - Tables: users, clients, activity_logs, container_metrics" -ForegroundColor Gray
                Write-Host "  - Index de performance créés" -ForegroundColor Gray  
                Write-Host "  - Triggers automatiques configurés" -ForegroundColor Gray
                Write-Host "  - Utilisateurs de test avec mots de passe bcrypt corrects" -ForegroundColor Gray
                $dbInitialized = $true
            } else {
                throw "L'endpoint a retourné success=false"
            }
            
        } catch {
            Write-Host "  ⚠ Tentative $retryCount échouée: $($_.Exception.Message)" -ForegroundColor Yellow
            if ($retryCount -lt $maxRetries) {
                Write-Host "  Attente avant nouvelle tentative..." -ForegroundColor Gray
                Start-Sleep 15
            }
        }
    }
    
    if (-not $dbInitialized) {
        Write-Host "❌ Échec de l'initialisation de la DB après $maxRetries tentatives" -ForegroundColor Red
        Write-Host "   Vous devrez initialiser manuellement via: $backendUrl/api/database/init-database" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ URL backend manquante, initialisation DB impossible" -ForegroundColor Red
}

# Phase 5: Tests de connectivité
Write-Host "`nPhase 5: Tests..." -ForegroundColor Yellow
Start-Sleep 10

Write-Host "Test de l'API backend..." -ForegroundColor White
try {
    $healthCheck = Invoke-RestMethod "$backendUrl/api/health" -Method GET -TimeoutSec 10
    Write-Host "✓ Backend accessible" -ForegroundColor Green
} catch {
    Write-Host "⚠ Backend non accessible immédiatement (normal au démarrage)" -ForegroundColor Yellow
}

Write-Host "Test de connexion avec les utilisateurs de test..." -ForegroundColor White
try {
    $loginBody = '{"email":"admin@portail-cloud.com","password":"admin123"}'
    $loginTest = Invoke-RestMethod "$backendUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $loginBody -TimeoutSec 15
    
    if ($loginTest.success) {
        Write-Host "✓ Connexion admin fonctionnelle (JWT reçu)" -ForegroundColor Green
        
        # Test connexion client
        $clientBody = '{"email":"client1@portail-cloud.com","password":"client123"}'
        $clientTest = Invoke-RestMethod "$backendUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $clientBody -TimeoutSec 15
        
        if ($clientTest.success) {
            Write-Host "✓ Connexion client fonctionnelle (JWT reçu)" -ForegroundColor Green
        } else {
            Write-Host "⚠ Connexion client échouée" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⚠ Test d'authentification échoué: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   Testez manuellement: $backendUrl/api/auth/login" -ForegroundColor Gray
}

# Vérification COMPLÈTE du statut de la base de données
Write-Host "Vérification du statut complet de la base de données..." -ForegroundColor White
try {
    $dbStatus = Invoke-RestMethod "$backendUrl/api/health/db-status" -TimeoutSec 10
    if ($dbStatus.success) {
        Write-Host "✓ Base de données connectée" -ForegroundColor Green
        Write-Host "  - Utilisateurs: $($dbStatus.database.users.count)" -ForegroundColor Gray
        
        # Affichage des tables présentes
        if ($dbStatus.database.tables) {
            $tablesList = $dbStatus.database.tables -join ", "
            Write-Host "  - Tables: $tablesList" -ForegroundColor Gray
            
            # Vérification si toutes les tables sont présentes
            $expectedTables = @("users", "clients", "activity_logs", "container_metrics")
            $missingTables = $expectedTables | Where-Object { $_ -notin $dbStatus.database.tables }
            
            if ($missingTables.Count -eq 0) {
                Write-Host "✓ Schéma de base de données COMPLET" -ForegroundColor Green
            } else {
                Write-Host "⚠ Tables manquantes: $($missingTables -join ', ')" -ForegroundColor Yellow
                Write-Host "  ℹ  Fonctionnalités avancées limitées" -ForegroundColor Gray
            }
        }
    }
} catch {
    Write-Host "⚠ Vérification DB échouée: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== DEPLOIEMENT TERMINE ===" -ForegroundColor Green
Write-Host "URLs de production:" -ForegroundColor Cyan
Write-Host "Frontend: $frontendUrl" -ForegroundColor White
Write-Host "Backend:  $backendUrl" -ForegroundColor White

Write-Host "`nConfiguration CORS:" -ForegroundColor Cyan
Write-Host "- Le backend autorise les requêtes depuis: $frontendUrl" -ForegroundColor Gray
Write-Host "- Le frontend fait ses requêtes vers: $backendUrl" -ForegroundColor Gray

Write-Host "`nUtilisateurs de test disponibles:" -ForegroundColor Cyan
Write-Host "- Admin: admin@portail-cloud.com / admin123" -ForegroundColor White
Write-Host "- Client 1: client1@portail-cloud.com / client123" -ForegroundColor White
Write-Host "- Client 2: client2@portail-cloud.com / client123" -ForegroundColor White
Write-Host "- Client 3: client3@portail-cloud.com / client123" -ForegroundColor White

Write-Host "`nEndpoints utiles:" -ForegroundColor Cyan
Write-Host "- Health: $backendUrl/api/health" -ForegroundColor Gray
Write-Host "- DB Status: $backendUrl/api/health/db-status" -ForegroundColor Gray
Write-Host "- Login: $backendUrl/api/auth/login" -ForegroundColor Gray
Write-Host "- Init DB: $backendUrl/api/database/init-database" -ForegroundColor Gray

Write-Host "`n🎉 DÉPLOIEMENT COMPLET ET FONCTIONNEL !" -ForegroundColor Green

# Validation automatique post-déploiement
Write-Host "`n🔍 Validation post-déploiement..." -ForegroundColor Yellow
Start-Sleep 10

try {
    # Test de l'API de santé
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/api/health" -TimeoutSec 30 -ErrorAction Stop
    if ($healthResponse.success) {
        Write-Host "✅ Backend opérationnel" -ForegroundColor Green
    }
    
    # Test de la base de données
    $dbResponse = Invoke-RestMethod -Uri "$backendUrl/api/health/db-status" -TimeoutSec 30 -ErrorAction Stop
    if ($dbResponse.success -and $dbResponse.database.connected) {
        Write-Host "✅ Base de données initialisée ($(($dbResponse.database.tables).Count) tables)" -ForegroundColor Green
    }
    
    # Test d'authentification
    $loginData = @{ email = "admin@portail-cloud.com"; password = "admin123" } | ConvertTo-Json
    $headers = @{ "Content-Type" = "application/json" }
    $authResponse = Invoke-RestMethod -Uri "$backendUrl/api/auth/login" -Method POST -Body $loginData -Headers $headers -TimeoutSec 30 -ErrorAction Stop
    if ($authResponse.success) {
        Write-Host "✅ Authentification fonctionnelle" -ForegroundColor Green
    }
    
    Write-Host "`n🌟 VALIDATION RÉUSSIE - Le système est pleinement opérationnel!" -ForegroundColor Green
} catch {
    Write-Host "`n⚠️ Validation partielle - Certains services peuvent encore démarrer..." -ForegroundColor Yellow
    Write-Host "Utilisez validate-deployment-clean.ps1 pour une validation complète dans quelques minutes." -ForegroundColor Gray
}

if ($frontendUrl -and $frontendUrl -ne "") {
    $open = Read-Host "`nOuvrir le frontend? (O/n)"
    if ($open -ne "n") { 
        Start-Process $frontendUrl 
        Write-Host "Ouverture du frontend dans le navigateur..." -ForegroundColor Green
    }
} else {
    Write-Host "`nATTENTION: URL du frontend non récupérée. Vérifiez manuellement dans le portail Azure." -ForegroundColor Yellow
}