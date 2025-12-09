param(
    [string]$ResourceGroup = "rg-container-platform",
    [string]$Location = "francecentral", 
    [string]$DbPassword = "MySecurePassword123!"
)

Write-Host "DEPLOIEMENT DIRECT AZURE - Container Platform" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan

# Test connexion Azure
Write-Host "Verification connexion Azure..." -ForegroundColor Yellow
$account = az account show --query name -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pas connecte a Azure - Executez: az login" -ForegroundColor Red
    exit 1
}
Write-Host "Connecte: $account" -ForegroundColor Green

# Obtenir subscription ID
$subscriptionId = az account show --query id -o tsv
Write-Host "Subscription: $subscriptionId" -ForegroundColor Cyan

# Etape 1: Resource Group
Write-Host ""
Write-Host "Etape 1: Creation Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output none
if ($LASTEXITCODE -eq 0) {
    Write-Host "Resource Group cree: $ResourceGroup" -ForegroundColor Green
} else {
    Write-Host "Erreur creation Resource Group" -ForegroundColor Red
    exit 1
}

# Etape 2: Terraform
Write-Host ""
Write-Host "Etape 2: Deploiement infrastructure..." -ForegroundColor Yellow
Set-Location terraform
terraform init -input=false
terraform plan -var="admin_password=$DbPassword" -out=tfplan -input=false
terraform apply -auto-approve tfplan
Set-Location ..

if ($LASTEXITCODE -eq 0) {
    Write-Host "Infrastructure deployee" -ForegroundColor Green
} else {
    Write-Host "Erreur deploiement Terraform" -ForegroundColor Red
    exit 1
}

# Etape 3: Build Backend
Write-Host ""
Write-Host "Etape 3: Build backend..." -ForegroundColor Yellow
Set-Location dashboard-backend
npm ci --silent
npm run build --silent
Compress-Archive -Path * -DestinationPath ..\backend.zip -Force -Exclude node_modules,*.log,coverage
Set-Location ..
Write-Host "Backend package cree" -ForegroundColor Green

# Etape 4: Build Frontend
Write-Host "Build frontend..." -ForegroundColor Yellow
Set-Location dashboard-frontend
npm ci --silent
npm run build --silent

# Detecter le dossier de build
if (Test-Path "out") {
    Compress-Archive -Path out\* -DestinationPath ..\frontend.zip -Force
} elseif (Test-Path "build") {
    Compress-Archive -Path build\* -DestinationPath ..\frontend.zip -Force
} elseif (Test-Path "dist") {
    Compress-Archive -Path dist\* -DestinationPath ..\frontend.zip -Force
} else {
    Compress-Archive -Path * -DestinationPath ..\frontend.zip -Force -Exclude node_modules,*.log
}
Set-Location ..
Write-Host "Frontend package cree" -ForegroundColor Green

# Etape 5: Deploiement App Services
Write-Host ""
Write-Host "Etape 5: Deploiement applications..." -ForegroundColor Yellow

Write-Host "Deploiement backend..." -ForegroundColor Cyan
az webapp deployment source config-zip --resource-group $ResourceGroup --name "container-platform-api" --src backend.zip --output none

Write-Host "Deploiement frontend..." -ForegroundColor Cyan  
az webapp deployment source config-zip --resource-group $ResourceGroup --name "container-platform-web" --src frontend.zip --output none

# Nettoyage
Remove-Item backend.zip, frontend.zip -ErrorAction SilentlyContinue

# Test final
Write-Host ""
Write-Host "Test de sante..." -ForegroundColor Yellow
Write-Host "Attente 30 secondes..." -ForegroundColor Cyan
Start-Sleep 30

$backendUrl = "https://container-platform-api.azurewebsites.net"
$frontendUrl = "https://container-platform-web.azurewebsites.net"

try {
    Invoke-RestMethod -Uri "$backendUrl/api/health" -TimeoutSec 30 | Out-Null
    Write-Host "API sante OK" -ForegroundColor Green
} catch {
    Write-Host "API en cours de demarrage..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "DEPLOIEMENT TERMINE !" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend: $frontendUrl" -ForegroundColor White
Write-Host "API:      $backendUrl" -ForegroundColor White
Write-Host ""
Write-Host "Test manuel: curl $backendUrl/api/health" -ForegroundColor Yellow