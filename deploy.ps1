# Container Manager Platform - Production Docker Deployment
Write-Host "🐳 DEPLOIEMENT PRODUCTION - Container Manager Platform" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Change to project directory
$projectPath = "c:\Users\basti\Documents\Workspace\Cloud Project\portail-cloud-container"
Set-Location $projectPath

# Verify Docker is running
Write-Host "Verification Docker..." -ForegroundColor Yellow
try {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not running"
    }
    Write-Host "Docker operationnel" -ForegroundColor Green
} catch {
    Write-Host "Docker non demarre. Lancement de Docker Desktop..." -ForegroundColor Red
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Host "Attendre que Docker demarre et relancer le script..." -ForegroundColor Yellow
    exit 1
}

# Cleanup before deployment
Write-Host ""
Write-Host "Nettoyage pre-deploiement..." -ForegroundColor Yellow
docker-compose down --remove-orphans 2>$null
docker container prune -f 2>$null
docker image prune -f 2>$null

Write-Host ""
Write-Host "Construction et deploiement..." -ForegroundColor Yellow
Write-Host "Ceci peut prendre quelques minutes..." -ForegroundColor Gray

try {
    docker-compose up -d --build --force-recreate
    if ($LASTEXITCODE -ne 0) {
        throw "Echec du deploiement Docker"
    }
    Write-Host "Services demarres avec succes!" -ForegroundColor Green
} catch {
    Write-Host "Echec du deploiement" -ForegroundColor Red
    Write-Host "Logs d'erreur:" -ForegroundColor Yellow
    docker-compose logs --tail=20
    exit 1
}

# Wait for services to be ready
Write-Host ""
Write-Host "Attente du demarrage des services..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Health checks
Write-Host ""
Write-Host "Verification de l'etat des services..." -ForegroundColor Blue

$services = @(
    @{Name="Backend API"; URL="http://localhost:5000/health"},
    @{Name="Frontend Dashboard"; URL="http://localhost:3000"},
    @{Name="Demo API"; URL="http://localhost:3001"},
    @{Name="Demo Web"; URL="http://localhost:8080"}
)

$allHealthy = $true
foreach ($service in $services) {
    Write-Host "  Verification $($service.Name)..." -ForegroundColor Gray
    
    $maxAttempts = 8
    $attempt = 0
    $healthy = $false
    
    while ($attempt -lt $maxAttempts) {
        $attempt++
        try {
            $response = Invoke-WebRequest -Uri $service.URL -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "    Service $($service.Name): OK" -ForegroundColor Green
                $healthy = $true
                break
            }
        } catch {
            if ($attempt -eq $maxAttempts) {
                Write-Host "    Service $($service.Name): Echec" -ForegroundColor Red
                $allHealthy = $false
                break
            }
            Start-Sleep -Seconds 3
        }
    }
}

# Final status
Write-Host ""
if ($allHealthy) {
    Write-Host "DEPLOIEMENT REUSSI!" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
} else {
    Write-Host "DEPLOIEMENT PARTIEL" -ForegroundColor Yellow
    Write-Host "===================" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Etat des containers:" -ForegroundColor Blue
docker-compose ps

Write-Host ""
Write-Host "URLs d'acces:" -ForegroundColor Blue
Write-Host "  Dashboard Manager:    http://localhost:3000" -ForegroundColor Cyan
Write-Host "  API Backend:          http://localhost:5000" -ForegroundColor Cyan
Write-Host "  Health Check:         http://localhost:5000/health" -ForegroundColor Cyan
Write-Host "  Demo Web Service:     http://localhost:8080" -ForegroundColor Cyan
Write-Host "  Demo API Service:     http://localhost:3001" -ForegroundColor Cyan

Write-Host ""
Write-Host "Commandes de gestion:" -ForegroundColor Blue
Write-Host "  Logs en temps reel:      docker-compose logs -f" -ForegroundColor Gray
Write-Host "  Arreter les services:    docker-compose down" -ForegroundColor Gray
Write-Host "  Redemarrer un service:   docker-compose restart <service>" -ForegroundColor Gray

Write-Host ""
Write-Host "Plateforme de gestion de containers operationnelle!" -ForegroundColor Green

# Auto-open dashboard
Write-Host ""
Start-Process "http://localhost:3000"
Write-Host "Dashboard ouvert dans le navigateur" -ForegroundColor Green