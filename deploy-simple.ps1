# PORTAIL CLOUD CONTAINER - AZURE DEPLOY
# Version PowerShell simple et fonctionnelle

$ErrorActionPreference = "Stop"

Write-Host "Deploiement Azure - Portail Cloud Container" -ForegroundColor Blue
Write-Host "===========================================" -ForegroundColor Blue

# Charger les variables .env
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Fichier .env cree. Modifiez ADMIN_EMAIL si necessaire." -ForegroundColor Yellow
}

# Lire les variables
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match "^([^#][^=]+)=(.+)$") {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Variables avec defaults
$ADMIN_EMAIL = $envVars["ADMIN_EMAIL"]
$PROJECT_NAME = if ($envVars["PROJECT_NAME"]) { $envVars["PROJECT_NAME"] } else { "portail-cloud" }
$ENVIRONMENT = if ($envVars["ENVIRONMENT"]) { $envVars["ENVIRONMENT"] } else { "dev" }
$LOCATION = if ($envVars["LOCATION"]) { $envVars["LOCATION"] } else { "West Europe" }

Write-Host "Configuration:"
Write-Host "  Email: $ADMIN_EMAIL"
Write-Host "  Projet: $PROJECT_NAME"
Write-Host "  Environnement: $ENVIRONMENT"
Write-Host "  Region: $LOCATION"

# Verifications
Write-Host "`nVerification des prerequis..." -ForegroundColor Yellow

# Azure CLI
$azCheck = Get-Command "az" -ErrorAction SilentlyContinue
if ($azCheck) {
    Write-Host "Azure CLI: OK" -ForegroundColor Green
} else {
    Write-Host "Azure CLI manquant!" -ForegroundColor Red
    exit 1
}

# Connexion Azure
try {
    $azAccount = az account show | ConvertFrom-Json
    Write-Host "Azure connecte: $($azAccount.user.name)" -ForegroundColor Green
    
    # Auto-update email si necessaire
    if ($ADMIN_EMAIL -eq "bastien.robert@student.junia.com") {
        $ADMIN_EMAIL = $azAccount.user.name
        (Get-Content ".env") -replace "ADMIN_EMAIL=.*", "ADMIN_EMAIL=$ADMIN_EMAIL" | Set-Content ".env"
        Write-Host "Email mis a jour automatiquement: $ADMIN_EMAIL" -ForegroundColor Green
    }
} catch {
    Write-Host "Non connecte a Azure. Executez: az login" -ForegroundColor Red
    exit 1
}

# Terraform
$tfCheck = Get-Command "terraform" -ErrorAction SilentlyContinue
if ($tfCheck) {
    Write-Host "Terraform: OK" -ForegroundColor Green
} else {
    Write-Host "Installation de Terraform..." -ForegroundColor Yellow
    
    $TfDir = "$env:USERPROFILE\terraform"
    New-Item -ItemType Directory -Path $TfDir -Force | Out-Null
    
    $TfUrl = "https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_windows_amd64.zip"
    Invoke-WebRequest -Uri $TfUrl -OutFile "$TfDir\terraform.zip"
    Expand-Archive -Path "$TfDir\terraform.zip" -DestinationPath $TfDir -Force
    Remove-Item "$TfDir\terraform.zip"
    
    $env:PATH = "$TfDir;$env:PATH"
    Write-Host "Terraform installe" -ForegroundColor Green
}

# Docker
$dockerCheck = Get-Command "docker" -ErrorAction SilentlyContinue
if ($dockerCheck) {
    Write-Host "Docker: OK" -ForegroundColor Green
} else {
    Write-Host "Docker manquant. Installez Docker Desktop" -ForegroundColor Red
    exit 1
}

# Configuration Terraform
Write-Host "`nConfiguration Terraform..." -ForegroundColor Yellow

$tfVars = @"
admin_email  = "$ADMIN_EMAIL"
project_name = "$PROJECT_NAME"
environment  = "$ENVIRONMENT"
location     = "$LOCATION"
"@

$tfVars | Out-File -FilePath "terraform\azure\terraform.tfvars" -Encoding UTF8
Write-Host "terraform.tfvars genere" -ForegroundColor Green

# Deploiement
Write-Host "`nDemarrage du deploiement..." -ForegroundColor Yellow

Push-Location "terraform\azure"

try {
    Write-Host "terraform init..."
    terraform init
    
    Write-Host "terraform plan..."
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: terraform plan a echoue" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Demarrage du deploiement de l'infrastructure..." -ForegroundColor Green
    terraform apply -auto-approve tfplan
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur: terraform apply a echoue" -ForegroundColor Red
        exit 1
    }
    
    # Récupérer les infos du registry
    Write-Host "Récupération des informations du registry..." -ForegroundColor Green
    $registryServer = terraform output -raw container_registry_login_server
    $registryUsername = terraform output -raw container_registry_admin_username
    $registryPassword = terraform output -raw container_registry_admin_password
    
    # Login au registry
    Write-Host "Connexion au Container Registry..." -ForegroundColor Green
    docker login $registryServer -u $registryUsername -p $registryPassword
    
    # Build et push des images
    Write-Host "Construction et publication des images Docker..." -ForegroundColor Green
    
    # Backend
    Write-Host "Build Backend..." -ForegroundColor Yellow
    docker build -t "$registryServer/portail-backend:latest" ./dashboard-backend
    docker push "$registryServer/portail-backend:latest"
    
    # Frontend  
    Write-Host "Build Frontend..." -ForegroundColor Yellow
    docker build -t "$registryServer/portail-frontend:latest" ./dashboard-frontend
    docker push "$registryServer/portail-frontend:latest"
    
    # Redémarrer les Container Apps pour utiliser les nouvelles images
    Write-Host "Redémarrage des Container Apps..." -ForegroundColor Green
    $resourceGroup = terraform output -raw resource_group_name
    az containerapp revision restart --name "$($env:PROJECT_NAME)-$($env:ENVIRONMENT)-backend" --resource-group $resourceGroup --revision-name latest
    az containerapp revision restart --name "$($env:PROJECT_NAME)-$($env:ENVIRONMENT)-frontend" --resource-group $resourceGroup --revision-name latest
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erreur terraform apply"
    }
    
    Write-Host "Infrastructure deployee !" -ForegroundColor Green
    
    # Docker
    Write-Host "`nBuild et push des images Docker..." -ForegroundColor Yellow
    
    $registryUrl = terraform output -raw container_registry_url
    $registryName = $registryUrl -replace "\.azurecr\.io$", ""
    
    az acr login --name $registryName
    
    Pop-Location  # Retour à la racine
    
    Write-Host "Build Backend..."
    docker build -t "$registryUrl/portail-backend:latest" .\dashboard-backend
    docker push "$registryUrl/portail-backend:latest"
    
    Write-Host "Build Frontend..."
    docker build -t "$registryUrl/portail-frontend:latest" .\dashboard-frontend
    docker push "$registryUrl/portail-frontend:latest"
    
    Write-Host "Images publiees !" -ForegroundColor Green
    
    Push-Location "terraform\azure"  # Retour pour les outputs
    
    Write-Host "`nAttente du demarrage (30s)..."
    Start-Sleep 30
    
    # Resultats
    Write-Host "`n" + "="*50 -ForegroundColor Green
    Write-Host "DEPLOIEMENT TERMINE !" -ForegroundColor Green
    Write-Host "="*50 -ForegroundColor Green
    
    Write-Host "`nURLs d'acces:"
    try {
        $frontend = terraform output -raw frontend_url
        $backend = terraform output -raw backend_url
        Write-Host "  Frontend: $frontend" -ForegroundColor Cyan
        Write-Host "  Backend:  $backend" -ForegroundColor Cyan
    } catch {
        Write-Host "  URLs en cours... Utilisez 'terraform output' dans quelques minutes"
    }
    
    Write-Host "`nComptes par defaut:"
    Write-Host "  Admin:  admin@portail-cloud.com / admin123"
    Write-Host "  Client: client1@portail-cloud.com / client123"
    
    Write-Host "`nPour nettoyer: .\destroy.ps1" -ForegroundColor Yellow
    
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location  # S'assurer qu'on revient à la racine
}