Write-Host "Configuration Azure GitHub Actions"
Write-Host "=================================="

$account = az account show --query name -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pas connecte a Azure - Utilisez: az login"
    exit 1
}

Write-Host "Connecte: $account"

$subscriptionId = az account show --query id -o tsv
$tenantId = az account show --query tenantId -o tsv

Write-Host "Subscription: $subscriptionId"
Write-Host "Tenant: $tenantId"

Write-Host "Tentative creation Service Principal..."

$spName = "github-sp-$(Get-Random)"
$result = az ad sp create-for-rbac --name $spName --role contributor --scopes "/subscriptions/$subscriptionId" --output json 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Service Principal cree!"
    Write-Host "Copiez ce JSON dans GitHub Secrets > AZURE_CREDENTIALS:"
    Write-Host $result
} else {
    Write-Host "Erreur creation Service Principal"
    Write-Host "Utilisez Azure Cloud Shell: https://shell.azure.com"
}
