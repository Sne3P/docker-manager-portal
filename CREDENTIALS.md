# Guide des Credentials - Container Management Platform
# Quels credentials utiliser et où les trouver

## 📋 Résumé des credentials nécessaires

### Pour Terraform (local) ✅ FAIT
Fichier: `terraform/terraform.tfvars`
```
admin_password = "MonMotDePasse123!"
```
✅ C'est configuré maintenant !

## 🔑 Pour Azure (2 options)

### Option 1: Azure CLI (Recommandé pour test local)

1. **Installer Azure CLI**:
   - Télécharger: https://aka.ms/installazurecliwindows
   - Ou via winget: `winget install -e --id Microsoft.AzureCLI`

2. **Se connecter**:
   ```powershell
   az login
   ```

3. **Tester Terraform**:
   ```powershell
   .\test-terraform.ps1
   ```

### Option 2: Service Principal (Pour GitHub Actions)

1. **Créer un Service Principal** (après avoir installé Azure CLI):
   ```powershell
   # Se connecter à Azure
   az login
   
   # Créer le service principal
   az ad sp create-for-rbac --name "sp-container-platform" --role contributor --scopes "/subscriptions/VOTRE_SUBSCRIPTION_ID"
   ```

2. **Copier le JSON de sortie** pour les secrets GitHub

## 🎯 Plan d'action recommandé

### Étape 1: Test local (MAINTENANT)
```powershell
# 1. Installer Azure CLI
winget install -e --id Microsoft.AzureCLI

# 2. Redémarrer PowerShell, puis:
az login

# 3. Tester Terraform
.\test-terraform.ps1
```

### Étape 2: GitHub Actions (APRÈS)
Une fois que Terraform fonctionne localement:
1. Créer Service Principal
2. Configurer secrets GitHub
3. Tester déploiement automatique

## 💡 Credentials par environnement

| Environnement | Credentials nécessaires |
|---------------|-------------------------|
| **Local (Terraform)** | ✅ terraform.tfvars (fait) + Azure CLI |
| **GitHub Actions** | Service Principal JSON + Secrets GitHub |
| **Production** | Automatique via GitHub Actions |

## 🚀 Prochaine étape

**Installez Azure CLI maintenant**:
```powershell
winget install -e --id Microsoft.AzureCLI
```

Puis redémarrez PowerShell et lancez:
```powershell
az login
.\test-terraform.ps1
```

C'est tout ! 🎊