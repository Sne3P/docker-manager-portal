param(
    [string]$ResourceGroup = "rg-container-platform",
    [string]$Location = "francecentral", 
    [string]$AppName = "container-platform",
    [string]$DbPassword = "MySecurePassword123!"
)

Write-Host "DEPLOIEMENT ULTRA-SIMPLE AZURE" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Cyan

# Test connexion Azure
$account = az account show --query name -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Connectez-vous a Azure: az login" -ForegroundColor Red
    exit 1
}
Write-Host "Connecte: $account" -ForegroundColor Green

# Variables
$backendApp = "$AppName-api"
$frontendApp = "$AppName-web"  
$dbServer = "$AppName-db-server"
$dbName = "$AppName-db"

Write-Host ""
Write-Host "Creation Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output none

Write-Host "Creation PostgreSQL..." -ForegroundColor Yellow
az postgres flexible-server create `
  --resource-group $ResourceGroup `
  --name $dbServer `
  --location $Location `
  --admin-user containeradmin `
  --admin-password $DbPassword `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --storage-size 32 `
  --version 13 `
  --public-access 0.0.0.0 `
  --output none

Write-Host "Creation base de donnees..." -ForegroundColor Yellow
az postgres flexible-server db create `
  --resource-group $ResourceGroup `
  --server-name $dbServer `
  --database-name $dbName `
  --output none

Write-Host "Creation App Service Plan..." -ForegroundColor Yellow
az appservice plan create `
  --resource-group $ResourceGroup `
  --name "$AppName-plan" `
  --location $Location `
  --sku B1 `
  --is-linux `
  --output none

Write-Host "Creation Backend App Service..." -ForegroundColor Yellow
az webapp create `
  --resource-group $ResourceGroup `
  --plan "$AppName-plan" `
  --name $backendApp `
  --runtime "NODE:18-lts" `
  --output none

Write-Host "Creation Frontend App Service..." -ForegroundColor Yellow  
az webapp create `
  --resource-group $ResourceGroup `
  --plan "$AppName-plan" `
  --name $frontendApp `
  --runtime "NODE:18-lts" `
  --output none

# Configuration backend
Write-Host "Configuration backend..." -ForegroundColor Yellow
$dbConnectionString = "postgresql://containeradmin:$DbPassword@$dbServer.postgres.database.azure.com:5432/$dbName?sslmode=require"

az webapp config appsettings set `
  --resource-group $ResourceGroup `
  --name $backendApp `
  --settings PORT=8000 JWT_SECRET="ultra-secret-key-2024" DATABASE_URL="$dbConnectionString" NODE_ENV=production `
  --output none

# Configuration frontend
az webapp config appsettings set `
  --resource-group $ResourceGroup `
  --name $frontendApp `
  --settings NEXT_PUBLIC_API_URL="https://$backendApp.azurewebsites.net" NODE_ENV=production `
  --output none

Write-Host ""
Write-Host "Build et deploiement..." -ForegroundColor Yellow

# Package backend simple
Write-Host "Package backend..." -ForegroundColor Cyan
Set-Location dashboard-backend
if (Test-Path "package.json") {
    $files = Get-ChildItem -Exclude node_modules,*.log,coverage | Compress-Archive -DestinationPath ..\backend.zip -Force -PassThru
    Write-Host "Backend package: $($files.Count) fichiers" -ForegroundColor Green
} else {
    Write-Host "Erreur: package.json non trouve" -ForegroundColor Red
    exit 1
}
Set-Location ..

# Package frontend simple  
Write-Host "Package frontend..." -ForegroundColor Cyan
Set-Location dashboard-frontend
if (Test-Path "package.json") {
    $files = Get-ChildItem -Exclude node_modules,*.log | Compress-Archive -DestinationPath ..\frontend.zip -Force -PassThru
    Write-Host "Frontend package: $($files.Count) fichiers" -ForegroundColor Green
} else {
    Write-Host "Erreur: package.json non trouve" -ForegroundColor Red
    exit 1
}
Set-Location ..

# Deploiement
Write-Host ""
Write-Host "Deploiement backend..." -ForegroundColor Cyan
az webapp deploy --resource-group $ResourceGroup --name $backendApp --src-path backend.zip --type zip --output none

Write-Host "Deploiement frontend..." -ForegroundColor Cyan
az webapp deploy --resource-group $ResourceGroup --name $frontendApp --src-path frontend.zip --type zip --output none

# Nettoyage
Remove-Item backend.zip, frontend.zip -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "DEPLOIEMENT TERMINE !" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""
Write-Host "URLs de votre application :" -ForegroundColor Yellow
Write-Host "Frontend: https://$frontendApp.azurewebsites.net" -ForegroundColor White
Write-Host "Backend:  https://$backendApp.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "Test sante backend:" -ForegroundColor Yellow
Write-Host "curl https://$backendApp.azurewebsites.net/api/health" -ForegroundColor White
Write-Host ""
Write-Host "Patientez 2-3 minutes pour la stabilisation complete." -ForegroundColor Cyan