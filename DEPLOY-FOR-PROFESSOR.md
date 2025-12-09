# 🚀 Déploiement Automatique sur Azure

> **Pour le professeur : Déploiement automatique en 3 étapes simples**

## 📋 Prérequis
- Compte Azure avec subscription active (essai gratuit OK)
- Compte GitHub

## 🎯 Déploiement en 3 étapes

### Étape 1: Fork le repository
1. Cliquez sur "Fork" en haut à droite
2. Gardez le nom par défaut ou personnalisez

### Étape 2: Configurer les secrets Azure
1. **Créer un Service Principal Azure** :
   ```bash
   # Dans Azure Cloud Shell (https://shell.azure.com) - PAS BESOIN D'INSTALLER QUOI QUE CE SOIT LOCALEMENT
   az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes "/subscriptions/$(az account show --query id -o tsv)" --sdk-auth
   ```

2. **Copier tout le JSON de sortie**

3. **Aller dans Settings > Secrets and variables > Actions de votre fork**

4. **Créer ces secrets** :
   - `AZURE_CREDENTIALS` → Coller le JSON du service principal
   - `DB_ADMIN_PASSWORD` → Un mot de passe sécurisé (ex: `SecurePass123!`)

### Étape 3: Déclencher le déploiement
1. **Modifier n'importe quel fichier** (ex: ajouter un espace dans README.md)
2. **Commit & Push sur main**
3. **🎉 GitHub Actions déploie automatiquement tout sur Azure !**

## ✅ Résultat attendu

Après ~10-15 minutes, vous aurez :
- ✅ Infrastructure Azure complète (App Services, Database, Registry)
- ✅ Application web fonctionnelle 
- ✅ API backend déployée
- ✅ Base de données PostgreSQL configurée

**URLs générées automatiquement** :
- Frontend: `https://app-container-platform-web-prod.azurewebsites.net`
- Backend: `https://app-container-platform-api-prod.azurewebsites.net`

## 🔍 Vérification

### Tester l'API
```bash
curl https://app-container-platform-api-prod.azurewebsites.net/api/health
```

### Connexion à l'application
- **Admin** : `admin` / `admin123`
- **Client** : `client1` / `client123`

## 🏗️ Technologies déployées

- **Infrastructure as Code** : Terraform
- **CI/CD** : GitHub Actions
- **Frontend** : Next.js sur Azure App Service
- **Backend** : Node.js/Express sur Azure App Service  
- **Database** : Azure PostgreSQL Flexible Server
- **Registry** : Azure Container Registry
- **Monitoring** : Health checks intégrés

## 🔧 Dépannage

### Si le déploiement échoue :
1. Vérifiez les logs dans **Actions** tab de GitHub
2. Assurez-vous que le service principal a les bonnes permissions
3. Vérifiez que `DB_ADMIN_PASSWORD` respecte les exigences Azure

### Pour nettoyer les ressources :
```bash
# Dans Azure Cloud Shell
az group delete --name "rg-container-platform-prod" --yes --no-wait
```

---

**🎓 Évaluation :**
- ✅ Application Cloud fonctionnelle
- ✅ Infrastructure as Code (Terraform)  
- ✅ CI/CD automatisé (GitHub Actions)
- ✅ Multiples services Cloud (Compute, Storage, Database)
- ✅ Reproductible depuis n'importe quel environnement
- ✅ Documentation complète