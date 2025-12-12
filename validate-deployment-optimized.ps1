# =============================================================
# SCRIPT DE VALIDATION UNIQUE OPTIMISÉ
# =============================================================
param([switch]$Verbose, [switch]$Quick)

$ErrorActionPreference = "Continue"

# Colors
$colors = @{
    Red = "Red"; Green = "Green"; Yellow = "Yellow"
    Cyan = "Cyan"; White = "White"; Gray = "Gray"
}

function Log { param($msg) Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $msg" -ForegroundColor $colors.Cyan }
function Success { param($msg) Write-Host "✓ $msg" -ForegroundColor $colors.Green }
function Warn { param($msg) Write-Host "⚠ $msg" -ForegroundColor $colors.Yellow }
function Error { param($msg) Write-Host "❌ $msg" -ForegroundColor $colors.Red }

Log "🔍 VALIDATION DU DÉPLOIEMENT PORTAIL CLOUD"

# Configuration
$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) { Error "Non connecté à Azure"; exit 1 }

$uniqueId = ($account.user.name -replace '[^a-zA-Z0-9]', '').ToLower().Substring(0, 8)
$resourceGroup = "rg-container-manager-$uniqueId"

Success "ID unique: $uniqueId | Groupe: $resourceGroup"

# ===========================
# 1. VERIFICATION DES RESSOURCES AZURE
# ===========================
Log "1️⃣ Vérification des ressources Azure..."

# Check resource group exists
if (-not (az group show --name $resourceGroup 2>$null)) {
    Error "Groupe de ressources '$resourceGroup' introuvable"
    exit 1
}

# Get container apps
$containerApps = az containerapp list --resource-group $resourceGroup --query '[].{Name:name,State:properties.provisioningState,Fqdn:properties.configuration.ingress.fqdn}' -o json 2>$null | ConvertFrom-Json

if (-not $containerApps -or $containerApps.Count -lt 2) {
    Error "Container Apps manquantes ou incomplètes"
    if ($Verbose -and $containerApps) {
        $containerApps | ForEach-Object { Write-Host "  - $($_.Name): $($_.State)" -ForegroundColor $colors.Gray }
    }
    exit 1
}

# Get database server
$dbServer = az postgres flexible-server list --resource-group $resourceGroup --query '[0].{Name:name,State:state}' -o json 2>$null | ConvertFrom-Json

if (-not $dbServer -or $dbServer.State -ne "Ready") {
    Error "Serveur PostgreSQL non prêt (État: $($dbServer.State))"
    exit 1
}

# Get ACR
$acr = az acr list --resource-group $resourceGroup --query '[0].{Name:name,LoginServer:loginServer}' -o json 2>$null | ConvertFrom-Json
if (-not $acr) {
    Error "Container Registry manquant"
    exit 1
}

Success "Ressources Azure OK (Apps: $($containerApps.Count), DB: Ready, ACR: OK)"

# ===========================
# 2. VERIFICATION DES URLS ET CONNECTIVITE
# ===========================
Log "2️⃣ Test de connectivité..."

$frontend = $containerApps | Where-Object { $_.Name -eq "frontend-$uniqueId" }
$backend = $containerApps | Where-Object { $_.Name -eq "backend-$uniqueId" }

if (-not $frontend -or -not $backend) {
    Error "Container Apps frontend ou backend manquants"
    exit 1
}

$frontendUrl = "https://$($frontend.Fqdn)"
$backendUrl = "https://$($backend.Fqdn)"

if ($Verbose) {
    Log "URLs détectées:"
    Write-Host "   Frontend: $frontendUrl" -ForegroundColor $colors.Gray
    Write-Host "   Backend:  $backendUrl" -ForegroundColor $colors.Gray
}

# Test frontend connectivity
try {
    $frontendTest = Invoke-WebRequest $frontendUrl -Method HEAD -TimeoutSec 10 -ErrorAction Stop
    if ($frontendTest.StatusCode -eq 200) {
        Success "Frontend accessible (HTTP $($frontendTest.StatusCode))"
    } else {
        Warn "Frontend réponse anormale (HTTP $($frontendTest.StatusCode))"
    }
} catch {
    Error "Frontend non accessible: $($_.Exception.Message)"
    exit 1
}

# ===========================
# 3. TEST DE L'API BACKEND
# ===========================
Log "3️⃣ Test de l'API backend..."

# Test health endpoint
try {
    $healthResponse = Invoke-RestMethod "$backendUrl/api/health" -TimeoutSec 15 -ErrorAction Stop
    if ($healthResponse.success) {
        Success "API Health OK"
        if ($Verbose -and $healthResponse.timestamp) {
            Write-Host "   Timestamp: $($healthResponse.timestamp)" -ForegroundColor $colors.Gray
        }
    } else {
        Warn "API Health réponse négative"
    }
} catch {
    Error "API Health inaccessible: $($_.Exception.Message)"
    exit 1
}

# Test database status (detailed)
try {
    $dbStatus = Invoke-RestMethod "$backendUrl/api/health/db-status" -TimeoutSec 15 -ErrorAction Stop
    if ($dbStatus.success -and $dbStatus.database.connected) {
        Success "Base de données connectée"
        if ($Verbose) {
            Write-Host "   Utilisateurs: $($dbStatus.database.users.count)" -ForegroundColor $colors.Gray
            if ($dbStatus.database.tables) {
                Write-Host "   Tables: $($dbStatus.database.tables -join ', ')" -ForegroundColor $colors.Gray
            }
        }
        
        # Check for complete schema
        $expectedTables = @("users", "clients", "activity_logs", "container_metrics")
        $missingTables = $expectedTables | Where-Object { $_ -notin $dbStatus.database.tables }
        
        if ($missingTables.Count -eq 0) {
            Success "Schéma DB complet"
        } else {
            Warn "Tables manquantes: $($missingTables -join ', ')"
        }
    } else {
        Error "Base de données non connectée"
        exit 1
    }
} catch {
    Error "Status DB inaccessible: $($_.Exception.Message)"
    exit 1
}

# ===========================
# 4. TEST D'AUTHENTIFICATION
# ===========================
Log "4️⃣ Test d'authentification..."

$testUsers = @(
    @{ email = "admin@portail-cloud.com"; password = "admin123"; role = "Admin" }
    @{ email = "client1@portail-cloud.com"; password = "client123"; role = "Client" }
)

$authSuccess = 0
foreach ($user in $testUsers) {
    try {
        $loginBody = @{ 
            email = $user.email
            password = $user.password 
        } | ConvertTo-Json
        
        $headers = @{ "Content-Type" = "application/json" }
        $authResponse = Invoke-RestMethod "$backendUrl/api/auth/login" -Method POST -Body $loginBody -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        
        if ($authResponse.success -and $authResponse.token) {
            Success "$($user.role) login OK"
            $authSuccess++
            if ($Verbose) {
                Write-Host "   Token reçu pour $($user.email)" -ForegroundColor $colors.Gray
            }
        } else {
            Warn "$($user.role) login échec (pas de token)"
        }
    } catch {
        Error "$($user.role) login erreur: $($_.Exception.Message)"
    }
}

if ($authSuccess -eq 0) {
    Error "Aucun utilisateur ne peut se connecter"
    exit 1
} elseif ($authSuccess -lt $testUsers.Count) {
    Warn "Authentification partielle ($authSuccess/$($testUsers.Count) utilisateurs)"
} else {
    Success "Authentification complète OK"
}

# ===========================
# 5. TESTS AVANCÉS (SI PAS QUICK)
# ===========================
if (-not $Quick) {
    Log "5️⃣ Tests avancés..."
    
    # Test container metrics endpoint (si admin connecté)
    if ($authSuccess -gt 0) {
        try {
            # Get admin token first
            $adminBody = @{ 
                email = "admin@portail-cloud.com"
                password = "admin123" 
            } | ConvertTo-Json
            $adminAuth = Invoke-RestMethod "$backendUrl/api/auth/login" -Method POST -Body $adminBody -Headers @{"Content-Type"="application/json"} -TimeoutSec 10
            
            if ($adminAuth.token) {
                $authHeaders = @{ 
                    "Content-Type" = "application/json"
                    "Authorization" = "Bearer $($adminAuth.token)"
                }
                
                # Test containers endpoint
                $containersResponse = Invoke-RestMethod "$backendUrl/api/containers" -Headers $authHeaders -TimeoutSec 10 -ErrorAction Stop
                Success "API Containers accessible"
                
                if ($Verbose -and $containersResponse.containers) {
                    Write-Host "   Containers détectés: $($containersResponse.containers.Count)" -ForegroundColor $colors.Gray
                }
            }
        } catch {
            Warn "Tests avancés échoués: $($_.Exception.Message)"
        }
    }
    
    # Test CORS configuration
    try {
        $corsTest = Invoke-WebRequest "$backendUrl/api/health" -Method OPTIONS -TimeoutSec 5 -ErrorAction Stop
        $corsHeaders = $corsTest.Headers
        if ($corsHeaders["Access-Control-Allow-Origin"]) {
            Success "CORS configuré"
            if ($Verbose) {
                Write-Host "   CORS Origin: $($corsHeaders['Access-Control-Allow-Origin'])" -ForegroundColor $colors.Gray
            }
        } else {
            Warn "CORS headers manquants"
        }
    } catch {
        Warn "Test CORS échoué: $($_.Exception.Message)"
    }
} else {
    Log "5️⃣ Tests avancés ignorés (mode --Quick)"
}

# ===========================
# RÉSUMÉ DE LA VALIDATION
# ===========================
Write-Host ""
Write-Host "===============================================" -ForegroundColor $colors.Cyan
Write-Host "📋 RÉSUMÉ DE LA VALIDATION" -ForegroundColor $colors.Cyan  
Write-Host "===============================================" -ForegroundColor $colors.Cyan
Write-Host ""

Success "✅ Infrastructure Azure: OK"
Success "✅ Connectivité réseau: OK"  
Success "✅ API Backend: OK"
Success "✅ Base de données: OK"

if ($authSuccess -eq $testUsers.Count) {
    Success "✅ Authentification: OK"
} else {
    Warn "⚠️ Authentification: Partielle"
}

Write-Host ""
Write-Host "🌐 URLs du système:" -ForegroundColor $colors.White
Write-Host "   Frontend: $frontendUrl" -ForegroundColor $colors.Gray
Write-Host "   Backend:  $backendUrl" -ForegroundColor $colors.Gray
Write-Host ""
Write-Host "🔑 Utilisateurs de test:" -ForegroundColor $colors.White
Write-Host "   • admin@portail-cloud.com / admin123" -ForegroundColor $colors.Gray
Write-Host "   • client1@portail-cloud.com / client123" -ForegroundColor $colors.Gray
Write-Host ""

$overallSuccess = ($authSuccess -gt 0)
if ($overallSuccess) {
    Success "🎉 SYSTÈME OPÉRATIONNEL - Validation réussie!"
    
    $openFrontend = Read-Host "Ouvrir le frontend? [Y/n]"
    if ($openFrontend -ne "n" -and $openFrontend -ne "N") {
        Start-Process $frontendUrl
        Success "Frontend ouvert dans le navigateur"
    }
} else {
    Error "❌ SYSTÈME NON OPÉRATIONNEL - Vérifiez les erreurs ci-dessus"
    exit 1
}

Write-Host ""
Success "Validation terminée à $((Get-Date).ToString('HH:mm:ss'))"