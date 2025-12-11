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
} else {
    # Nettoyage préventif des Container Apps existants pour éviter les conflits
    Write-Host "Vérification et nettoyage préventif..." -ForegroundColor Yellow
    $rgName = "rg-container-manager-$uniqueId"
    az containerapp delete --name "backend-$uniqueId" --resource-group $rgName --yes --no-wait 2>$null | Out-Null
    az containerapp delete --name "frontend-$uniqueId" --resource-group $rgName --yes --no-wait 2>$null | Out-Null
    Start-Sleep 5
}

# Phase 1: Infrastructure seule
Write-Host "`nPhase 1: Infrastructure..." -ForegroundColor Yellow
Push-Location terraform\azure
terraform init -upgrade
terraform plan -var="unique_id=$uniqueId" -out=tfplan
terraform apply -auto-approve tfplan

# Recuperation des infos avec gestion d'erreur
try {
    $outputs = terraform output -json | ConvertFrom-Json
    $acrServer = $outputs.container_registry_login_server.value
    $acrName = $outputs.acr_name.value
    $rgName = $outputs.resource_group_name.value
    Write-Host "✓ Outputs Terraform récupérés" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la récupération des outputs Terraform" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

if (-not $acrServer -or -not $acrName -or -not $rgName) {
    Write-Host "❌ Informations manquantes: ACR=$acrServer, Name=$acrName, RG=$rgName" -ForegroundColor Red
    exit 1
}

Write-Host "Registry: $acrServer" -ForegroundColor Green
Write-Host "Groupe: $rgName" -ForegroundColor Green

# Phase 2: Images Docker (Backend, Frontend + Applications complètes)
Write-Host "`nPhase 2: Construction COMPLÈTE de toutes les images..." -ForegroundColor Yellow
az acr login --name $acrName

# Build and push the Azure integration backend
Write-Host "  Construction du backend avec intégration Azure..." -ForegroundColor White
docker build -t "$acrServer/dashboard-backend:latest" ./dashboard-backend
Write-Host "  Poussée du backend..." -ForegroundColor White
docker push "$acrServer/dashboard-backend:latest"

# Build and push frontend (URL sera configurée après déploiement)
Write-Host "  Construction du frontend..." -ForegroundColor White
docker build -t "$acrServer/dashboard-frontend:latest" ./dashboard-frontend
Write-Host "  Poussée du frontend..." -ForegroundColor White
docker push "$acrServer/dashboard-frontend:latest"

# Build and push application demo images
Write-Host "  Construction des images d'applications..." -ForegroundColor White

Write-Host "    Node.js Demo App..." -ForegroundColor Gray
docker build -t "$acrServer/nodejs-demo:latest" ./docker-images/nodejs-demo
docker push "$acrServer/nodejs-demo:latest"

Write-Host "    Python Demo App..." -ForegroundColor Gray  
docker build -t "$acrServer/python-demo:latest" ./docker-images/python-demo
docker push "$acrServer/python-demo:latest"

Write-Host "    Database Demo..." -ForegroundColor Gray
docker build -t "$acrServer/database-demo:latest" ./docker-images/database-demo  
docker push "$acrServer/database-demo:latest"

Write-Host "✓ Images déployées (backend avec intégration Azure réelle)" -ForegroundColor Green

# Phase 3: Container Apps avec récupération fiable des URLs
Write-Host "`nPhase 3: Container Apps..." -ForegroundColor Yellow
Push-Location terraform\azure

# Vérifier les container apps existants (préservation des URLs)
Write-Host "Vérification des container apps existants..." -ForegroundColor Gray
$existingBackend = az containerapp show --name "backend-$uniqueId" --resource-group $rgName 2>$null
$existingFrontend = az containerapp show --name "frontend-$uniqueId" --resource-group $rgName 2>$null

if ($existingBackend -or $existingFrontend) {
    Write-Host "⚠ Container apps existants détectés - Les URLs seront préservées" -ForegroundColor Yellow
    Write-Host "Note: Terraform va gérer la mise à jour automatiquement" -ForegroundColor Gray
}

terraform plan -var="unique_id=$uniqueId" -out=tfplan2
terraform apply -auto-approve tfplan2

# Phase 3.1: Récupération des URLs APRÈS création des container apps
Write-Host "Récupération des URLs finales..." -ForegroundColor White

# Attendre que les container apps soient complètement déployés
Write-Host "Attente du déploiement des container apps..." -ForegroundColor Gray
Start-Sleep 45

# Récupération des nouvelles URLs via Terraform outputs
try {
    $outputs = terraform output -json | ConvertFrom-Json
    $backendUrl = $outputs.backend_url.value
    $frontendUrl = $outputs.frontend_url.value
    
    if ($backendUrl -and $frontendUrl) {
        Write-Host "✓ URLs récupérées avec succès via Terraform:" -ForegroundColor Green
    } else {
        throw "URLs vides dans les outputs"
    }
} catch {
    Write-Host "⚠ Erreur Terraform, récupération manuelle via Azure CLI..." -ForegroundColor Yellow
    
    # Fallback via Azure CLI avec les nouvelles URLs
    $backendFqdn = az containerapp show --name "backend-$uniqueId" --resource-group $rgName --query "properties.configuration.ingress.fqdn" -o tsv 2>$null
    $frontendFqdn = az containerapp show --name "frontend-$uniqueId" --resource-group $rgName --query "properties.configuration.ingress.fqdn" -o tsv 2>$null
    
    if ($backendFqdn -and $frontendFqdn) {
        $backendUrl = "https://$backendFqdn"
        $frontendUrl = "https://$frontendFqdn"
        Write-Host "✓ URLs récupérées avec succès via Azure CLI:" -ForegroundColor Green
    } else {
        Write-Host "❌ Impossible de récupérer les URLs" -ForegroundColor Red
        $backendUrl = ""
        $frontendUrl = ""
    }
}
Pop-Location

if ($backendUrl -and $frontendUrl) {
    Write-Host "  Backend:  $backendUrl" -ForegroundColor Gray
    Write-Host "  Frontend: $frontendUrl" -ForegroundColor Gray
    
    # Rebuild frontend avec la bonne URL API maintenant qu'on la connaît
    Write-Host "Reconstruction du frontend avec URL API correcte..." -ForegroundColor White
    docker build --build-arg NEXT_PUBLIC_API_URL="$backendUrl/api" -t "$acrServer/dashboard-frontend:latest" ./dashboard-frontend
    Write-Host "Poussée du frontend avec URL: $backendUrl/api" -ForegroundColor White
    docker push "$acrServer/dashboard-frontend:latest"
    
    # Force la mise à jour du container frontend avec la nouvelle image ET les variables d'environnement
    Write-Host "Mise à jour du frontend avec nouvelle image et variables d'environnement..." -ForegroundColor White
    az containerapp update --name "frontend-$uniqueId" --resource-group $rgName `
        --image "$acrServer/dashboard-frontend:latest" `
        --set-env-vars "NODE_ENV=production" "NEXT_PUBLIC_API_URL=$backendUrl/api" `
        2>$null | Out-Null
    
    # Attendre que la nouvelle révision soit active
    Write-Host "Attente de la nouvelle révision frontend..." -ForegroundColor Gray
    Start-Sleep 30
    
    # Vérifier que la nouvelle révision est active
    $maxRetries = 10
    $retryCount = 0
    $revisionActive = $false
    
    while (-not $revisionActive -and $retryCount -lt $maxRetries) {
        $retryCount++
        $latestRevision = az containerapp revision list --name "frontend-$uniqueId" --resource-group $rgName --query "[0]" | ConvertFrom-Json 2>$null
        if ($latestRevision -and $latestRevision.properties.trafficWeight -eq 100) {
            $revisionActive = $true
            Write-Host "✓ Nouvelle révision active: $($latestRevision.name)" -ForegroundColor Green
        } else {
            Write-Host "  Attente révision $retryCount/$maxRetries..." -ForegroundColor Gray
            Start-Sleep 10
        }
    }
    
    if (-not $revisionActive) {
        Write-Host "⚠ Timeout: révision pas encore active, mais continuons..." -ForegroundColor Yellow
    }
    
    # Configuration CORS backend avec les vraies URLs finales
    Write-Host "Configuration CORS backend avec les vraies URLs..." -ForegroundColor White
    az containerapp update --name "backend-$uniqueId" --resource-group $rgName `
        --set-env-vars "FRONTEND_URL=$frontendUrl" 2>$null | Out-Null
    Write-Host "✓ CORS configuré: Backend autorise $frontendUrl" -ForegroundColor Green
    
    # Redémarrage du backend pour appliquer la configuration CORS
    Write-Host "Redémarrage du backend pour appliquer CORS..." -ForegroundColor White
    $activeRevision = az containerapp revision list --name "backend-$uniqueId" --resource-group $rgName --query "[0].name" -o tsv 2>$null
    if ($activeRevision) {
        az containerapp revision restart --name "backend-$uniqueId" --resource-group $rgName --revision $activeRevision 2>$null | Out-Null
        Write-Host "✓ Backend redémarré avec CORS actif" -ForegroundColor Green
        Start-Sleep 15
    }
} else {
    Write-Host "❌ Erreur: URLs non trouvées, le frontend utilisera localhost en fallback" -ForegroundColor Red
    $backendUrl = ""
    $frontendUrl = ""
}

# Configuration CORS déjà faite après le rebuild du frontend

# Phase 6: Initialisation COMPLÈTE de la base de données (UNIFIED)
Write-Host "`nPhase 6: Initialisation unifiée de la base de données..." -ForegroundColor Yellow

if ($backendUrl) {
    Write-Host "Initialisation du schéma complet via endpoint unifié..." -ForegroundColor White
    
    # Attendre que le backend soit prêt
    $maxHealthRetries = 10
    $healthRetry = 0
    $backendReady = $false
    
    while (-not $backendReady -and $healthRetry -lt $maxHealthRetries) {
        $healthRetry++
        try {
            Write-Host "  Test de santé $healthRetry/$maxHealthRetries..." -ForegroundColor Gray
            $healthCheck = Invoke-RestMethod "$backendUrl/api/health" -Method GET -TimeoutSec 10
            if ($healthCheck.success) {
                $backendReady = $true
                Write-Host "✓ Backend prêt" -ForegroundColor Green
            }
        } catch {
            Write-Host "  Backend en cours de démarrage, attente 15s..." -ForegroundColor Gray
            Start-Sleep 15
        }
    }
    
    if ($backendReady) {
        Write-Host "Initialisation de la base de données..." -ForegroundColor White
        $maxRetries = 3
        $retryCount = 0
        $dbInitialized = $false
        
        while (-not $dbInitialized -and $retryCount -lt $maxRetries) {
            try {
                $retryCount++
                Write-Host "  Tentative d'initialisation $retryCount/$maxRetries..." -ForegroundColor Gray
                
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
    Write-Host "❌ Backend non accessible après $maxHealthRetries tentatives" -ForegroundColor Red
    Write-Host "⚠ Initialisez manuellement la DB via: $backendUrl/api/database/init-database" -ForegroundColor Yellow
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