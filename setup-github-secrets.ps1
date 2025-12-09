# Script de configuration des credentials Azure pour GitHub Actions
# Ce script vous guide pour configurer tous les secrets nécessaires

Write-Host "🔐 Configuration des credentials Azure pour GitHub Actions" -ForegroundColor Green
Write-Host ""

# Étape 1: Créer un Service Principal Azure
Write-Host "📋 Étape 1: Création du Service Principal Azure" -ForegroundColor Yellow
Write-Host ""
Write-Host "Exécutez cette commande dans Azure CLI :" -ForegroundColor Cyan
Write-Host ""

$subscriptionId = Read-Host "Entrez votre Subscription ID Azure"
$resourceGroup = Read-Host "Entrez le nom du Resource Group (ex: rg-container-platform-prod)"
$servicePrincipalName = "sp-container-platform-github"

Write-Host ""
Write-Host "az ad sp create-for-rbac --name `"$servicePrincipalName`" --role contributor --scopes `"/subscriptions/$subscriptionId/resourceGroups/$resourceGroup`" --sdk-auth" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  Copiez TOUT le JSON de sortie, vous en aurez besoin pour AZURE_CREDENTIALS" -ForegroundColor Red
Write-Host ""

# Étape 2: Container Registry
Write-Host "📋 Étape 2: Configuration du Container Registry" -ForegroundColor Yellow
Write-Host ""

$registryName = Read-Host "Entrez le nom du Container Registry (ex: acrcontainerplatformprod)"

Write-Host ""
Write-Host "Exécutez ces commandes :" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Activer l'admin sur le registry" -ForegroundColor Gray
Write-Host "az acr update --name $registryName --admin-enabled true" -ForegroundColor Green
Write-Host ""
Write-Host "# Récupérer les credentials" -ForegroundColor Gray
Write-Host "az acr credential show --name $registryName" -ForegroundColor Green
Write-Host ""

# Étape 3: Secrets GitHub à configurer
Write-Host "📋 Étape 3: Secrets GitHub à configurer" -ForegroundColor Yellow
Write-Host ""
Write-Host "Allez sur GitHub: Settings > Secrets and Variables > Actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "Créez ces secrets :" -ForegroundColor White
Write-Host ""

$secrets = @(
    @{Name="AZURE_CREDENTIALS"; Description="JSON complet du service principal (étape 1)"},
    @{Name="AZURE_SUBSCRIPTION_ID"; Description="Votre Subscription ID Azure"},
    @{Name="AZURE_RESOURCE_GROUP"; Description="$resourceGroup"},
    @{Name="AZURE_REGISTRY_NAME"; Description="$registryName"},
    @{Name="AZURE_REGISTRY_USERNAME"; Description="Username du registry (étape 2)"},
    @{Name="AZURE_REGISTRY_PASSWORD"; Description="Password du registry (étape 2)"},
    @{Name="DB_ADMIN_PASSWORD"; Description="Mot de passe sécurisé pour PostgreSQL (ex: MySecurePass123!)"}
)

foreach($secret in $secrets) {
    Write-Host "🔑 $($secret.Name)" -ForegroundColor Green
    Write-Host "   Description: $($secret.Description)" -ForegroundColor Gray
    Write-Host ""
}

# Étape 4: Test local Terraform
Write-Host "📋 Étape 4: Tester Terraform localement" -ForegroundColor Yellow
Write-Host ""
Write-Host "cd terraform" -ForegroundColor Green
Write-Host "cp terraform.tfvars.example terraform.tfvars" -ForegroundColor Green
Write-Host "# Éditez terraform.tfvars avec vos valeurs" -ForegroundColor Gray
Write-Host "terraform init" -ForegroundColor Green
Write-Host "terraform plan" -ForegroundColor Green
Write-Host ""

Write-Host "✅ Configuration terminée !" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Prochaines étapes :" -ForegroundColor Cyan
Write-Host "1. Configurez les secrets GitHub" -ForegroundColor White
Write-Host "2. Testez Terraform localement" -ForegroundColor White
Write-Host "3. Pushez sur GitHub pour déclencher le déploiement" -ForegroundColor White