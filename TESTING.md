# Plan de test complet - Container Management Platform
# Guide étape par étape pour tester en conditions réelles

## 🎯 Plan de test Azure + GitHub Actions

### Étape 1: Préparation Azure (LOCAL)
```powershell
# 1. Connectez-vous à Azure
az login

# 2. Créez un Resource Group (si nécessaire)
az group create --name "rg-container-platform-prod" --location "West Europe"

# 3. Testez Terraform localement
.\test-terraform.ps1
```

### Étape 2: Configuration GitHub (GITHUB)
```powershell
# 1. Configurez les secrets GitHub
.\setup-github-secrets.ps1

# 2. Créez ces secrets sur GitHub:
# https://github.com/Sne3P/docker-manager-portal/settings/secrets/actions
```

**Secrets obligatoires:**
- `AZURE_CREDENTIALS` - JSON du service principal
- `AZURE_SUBSCRIPTION_ID` - Votre subscription ID
- `AZURE_RESOURCE_GROUP` - rg-container-platform-prod
- `AZURE_REGISTRY_NAME` - acrcontainerplatformprod
- `AZURE_REGISTRY_USERNAME` - Username du registry
- `AZURE_REGISTRY_PASSWORD` - Password du registry  
- `DB_ADMIN_PASSWORD` - Mot de passe PostgreSQL sécurisé

### Étape 3: Test Infrastructure (GITHUB ACTIONS)
1. **Allez sur GitHub Actions**: https://github.com/Sne3P/docker-manager-portal/actions
2. **Lancez "Test Infrastructure (Manual)"**
3. **Options de test:**
   - `deploy_infrastructure: false` (test uniquement)
   - `build_images: false` (test uniquement)

### Étape 4: Test Déploiement Partiel (GITHUB ACTIONS)
1. **Relancez "Test Infrastructure (Manual)"**
2. **Options:**
   - `deploy_infrastructure: true` (déploie vraiment)
   - `build_images: false` (pas encore)

### Étape 5: Test Déploiement Complet (GITHUB ACTIONS)
1. **Relancez "Test Infrastructure (Manual)"**
2. **Options:**
   - `deploy_infrastructure: true`
   - `build_images: true`

### Étape 6: Test Production (GITHUB ACTIONS)
1. **Push sur main** → Déploiement automatique complet
2. **Vérifiez les URLs de production**

## 🔧 Commandes utiles pour débugger

### Vérifier l'infrastructure
```powershell
# Lister les ressources créées
az resource list --resource-group "rg-container-platform-prod" --output table

# Vérifier le registry
az acr repository list --name "acrcontainerplatformprod" --output table

# Vérifier les App Services
az webapp list --resource-group "rg-container-platform-prod" --output table
```

### Vérifier les logs
```powershell
# Logs du backend
az webapp log tail --name "app-container-platform-api-prod" --resource-group "rg-container-platform-prod"

# Logs du frontend
az webapp log tail --name "app-container-platform-web-prod" --resource-group "rg-container-platform-prod"
```

### Nettoyer en cas de problème
```powershell
# Supprimer tout le resource group (ATTENTION!)
az group delete --name "rg-container-platform-prod" --yes --no-wait
```

## 🎊 Résultat attendu

Si tout fonctionne, vous aurez:
- ✅ Infrastructure Azure déployée automatiquement
- ✅ Applications fonctionnelles sur Azure App Services
- ✅ Base de données PostgreSQL configurée
- ✅ Container Registry avec les images
- ✅ CI/CD pipeline fonctionnel
- ✅ URLs de production accessibles

**URLs finales:**
- Backend API: `https://app-container-platform-api-prod.azurewebsites.net`
- Frontend: `https://app-container-platform-web-prod.azurewebsites.net`
- Registry: `acrcontainerplatformprod.azurecr.io`

## 🆘 En cas de problème

1. **Vérifiez les secrets GitHub** (erreurs les plus fréquentes)
2. **Consultez les logs GitHub Actions** pour voir où ça coince
3. **Testez Terraform localement** d'abord avec `.\test-terraform.ps1`
4. **Vérifiez les permissions Azure** du service principal

## 💰 Estimation des coûts Azure

**Test/Dev (quelques heures):** ~2-5€
**Production mensuelle:** ~15-30€
- App Service Basic B1: ~13€/mois
- PostgreSQL Basic: ~8€/mois  
- Container Registry Basic: ~4€/mois
- Application Gateway: ~20€/mois (optionnel)