param(
    [string]$ResourceGroup = "rg-container-test",
    [string]$Location = "francecentral", 
    [string]$AppName = "container-test-$(Get-Random)"
)

Write-Host "DEPLOIEMENT AZURE FONCTIONNEL" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Cyan

# Test connexion
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Azure CLI non installe" -ForegroundColor Red
    exit 1
}

$account = az account show --query name -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Connectez-vous: az login" -ForegroundColor Red  
    exit 1
}
Write-Host "Azure: $account" -ForegroundColor Green

Write-Host ""
Write-Host "Creation Resource Group: $ResourceGroup" -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output table

Write-Host ""
Write-Host "Creation App Service Plan (Windows)..." -ForegroundColor Yellow
az appservice plan create `
  --resource-group $ResourceGroup `
  --name "$AppName-plan" `
  --sku F1 `
  --output table

Write-Host ""  
Write-Host "Creation Web App Backend..." -ForegroundColor Yellow
$backendApp = "$AppName-api"
az webapp create `
  --resource-group $ResourceGroup `
  --plan "$AppName-plan" `
  --name $backendApp `
  --output table

Write-Host ""
Write-Host "Creation Web App Frontend..." -ForegroundColor Yellow
$frontendApp = "$AppName-web"
az webapp create `
  --resource-group $ResourceGroup `
  --plan "$AppName-plan" `
  --name $frontendApp `
  --output table

Write-Host ""
Write-Host "Configuration Backend..." -ForegroundColor Yellow
az webapp config appsettings set `
  --resource-group $ResourceGroup `
  --name $backendApp `
  --settings WEBSITE_NODE_DEFAULT_VERSION="~18" PORT=8000 NODE_ENV=production `
  --output table

Write-Host "Configuration Frontend..." -ForegroundColor Yellow  
az webapp config appsettings set `
  --resource-group $ResourceGroup `
  --name $frontendApp `
  --settings WEBSITE_NODE_DEFAULT_VERSION="~18" NEXT_PUBLIC_API_URL="https://$backendApp.azurewebsites.net" `
  --output table

Write-Host ""
Write-Host "DEPLOIEMENT TERMINE !" -ForegroundColor Green
Write-Host "Applications creees :" -ForegroundColor Yellow
Write-Host "Backend:  https://$backendApp.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Frontend: https://$frontendApp.azurewebsites.net" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pour deployer le code :" -ForegroundColor Yellow
Write-Host "1. Allez dans le portail Azure" -ForegroundColor White
Write-Host "2. App Services > $backendApp > Deployment Center" -ForegroundColor White  
Write-Host "3. Connectez votre repo GitHub" -ForegroundColor White
Write-Host ""
Write-Host "Ou utilisez az webapp deploy:" -ForegroundColor Yellow
Write-Host "az webapp deploy --resource-group $ResourceGroup --name $backendApp --src-path votre-code.zip --type zip" -ForegroundColor White
Write-Host ""
Write-Host "Pour supprimer :" -ForegroundColor Red
Write-Host "az group delete --name $ResourceGroup --yes --no-wait" -ForegroundColor White