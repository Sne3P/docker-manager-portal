# 🚀 Test du Déploiement - Guide Rapide

## Méthode Alternative : GitHub + Azure CLI

Puisque les permissions pour créer un Service Principal sont bloquées, utilisons votre compte personnel Azure.

### ✅ Étape 1 : Obtenir vos Identifiants Azure

Dans **Azure Cloud Shell** ou votre terminal local :

```bash
# 1. Login à Azure (déjà fait dans Cloud Shell)
az login

# 2. Obtenir votre Subscription ID
az account show --query id -o tsv

# 3. Obtenir votre Tenant ID  
az account show --query tenantId -o tsv

# 4. Créer des identifiants au format GitHub Actions
az ad sp create-for-rbac --name "github-actions-container-platform" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --output json
```

### ✅ Étape 2 : Configuration GitHub

1. **Aller dans Settings → Secrets and variables → Actions**

2. **Créer 2 secrets :**

   - `AZURE_CREDENTIALS` : Coller tout le JSON de l'étape 1
   - `DB_ADMIN_PASSWORD` : Un mot de passe sécurisé (ex: `MySecurePassword123!`)

### ✅ Étape 3 : Déclenchement

```bash
# Commit et push (depuis votre dossier projet)
git add .
git commit -m "Deploy container platform"
git push origin main
```

## 🎯 Alternative si Service Principal ne marche pas

Si la création du Service Principal échoue encore, voici la solution SIMPLIFIÉE :

### Option A : Deploy Script Manuel

```bash
# 1. Créer le script de déploiement local
./scripts/deploy-local.ps1

# 2. Suivre les instructions affichées
```

### Option B : Azure CLI Direct 

```bash
# Dans Azure Cloud Shell directement :
git clone https://github.com/Sne3P/docker-manager-portal.git
cd docker-manager-portal
./deploy-azure.sh
```

## 🔧 Résolution des Problèmes

- **Permission denied** → Utiliser Azure Cloud Shell
- **Resource exists** → Terraform gère automatiquement
- **Build failed** → Vérifier les logs GitHub Actions

## ✨ Résultat Attendu

Après déploiement réussi :
- **Frontend :** `https://container-platform-web.azurewebsites.net`
- **API :** `https://container-platform-api.azurewebsites.net/api/health`
- **Base de données :** PostgreSQL Azure automatiquement configurée

---

**🎓 Pour le professeur :** Fork → 2 secrets → Push = Déploiement automatique !