# 🚀 Configuration GitHub Actions - Guide Step-by-Step

## Objectif : Tester le déploiement complet CI/CD

### Étape 1: Créer Service Principal via Azure Portal

1. **Allez sur Azure Portal** : https://portal.azure.com
2. **Azure Active Directory** > **App registrations** > **New registration**
3. **Name** : `github-actions-container-platform`
4. **Supported account types** : Single tenant
5. Cliquez **Register**

### Étape 2: Créer Client Secret

1. Dans votre app registration, allez à **Certificates & secrets**
2. **Client secrets** > **New client secret**
3. **Description** : `GitHub Actions Secret`
4. **Expires** : 24 months
5. Cliquez **Add**
6. **⚠️ COPIEZ LA VALUE IMMÉDIATEMENT** (elle ne sera plus visible)

### Étape 3: Donner les permissions

1. **Subscriptions** (dans la barre de recherche)
2. Sélectionnez votre subscription : **Azure for Students**
3. **Access control (IAM)** > **Add role assignment**
4. **Role** : Contributor
5. **Assign access to** : User, group, or service principal
6. **Select** : Cherchez `github-actions-container-platform`
7. Cliquez **Save**

### Étape 4: Récupérer les informations

Notez ces valeurs :
- **Application (client) ID** : Dans Overview de votre app registration
- **Directory (tenant) ID** : Dans Overview de votre app registration  
- **Client secret value** : Copié à l'étape 2
- **Subscription ID** : `6df1bf9f-c8e8-4c71-aeb6-7d691adf418b`

### Étape 5: Configurer les secrets GitHub

1. Allez sur https://github.com/Sne3P/docker-manager-portal/settings/secrets/actions
2. **New repository secret** pour chacun :

#### Secret 1: AZURE_CREDENTIALS
```json
{
  "clientId": "VOTRE_CLIENT_ID",
  "clientSecret": "VOTRE_CLIENT_SECRET",
  "subscriptionId": "6df1bf9f-c8e8-4c71-aeb6-7d691adf418b",
  "tenantId": "19e51c11-d919-4a98-899d-9b9dc33f4e04"
}
```

#### Secret 2: DB_ADMIN_PASSWORD
```
MonMotDePasse123!
```

### Étape 6: Déclencher le déploiement

1. **Modifier n'importe quel fichier** (ex: ajouter un espace dans README.md)
2. **Commit & Push**
3. **Allez dans Actions** : https://github.com/Sne3P/docker-manager-portal/actions
4. **Regardez le workflow s'exécuter** ! 🎉

### Résultat attendu (15-20 min)

- ✅ Infrastructure Azure créée automatiquement
- ✅ Applications déployées sur Azure App Services
- ✅ Base PostgreSQL configurée
- ✅ URLs de production disponibles

## 🔧 URLs finales attendues

- **Backend** : `https://app-container-platform-api-prod.azurewebsites.net`
- **Frontend** : `https://app-container-platform-web-prod.azurewebsites.net`
- **Health Check** : `https://app-container-platform-api-prod.azurewebsites.net/api/health`

## ⚡ Test rapide de l'app

Une fois déployé :
```bash
# Test API
curl https://app-container-platform-api-prod.azurewebsites.net/api/health

# Test login
curl -X POST https://app-container-platform-api-prod.azurewebsites.net/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin","password":"admin123"}'
```

## 🎊 Connexion à l'app web

- **URL** : https://app-container-platform-web-prod.azurewebsites.net
- **Admin** : `admin` / `admin123`
- **Client** : `client1` / `client123`