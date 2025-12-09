# Test du déploiement complet - Plan d'action

## 🎯 Objectif
Tester le workflow de déploiement complet pour valider que tout fonctionne avant évaluation du prof.

## 🚀 Option 1: Test GitHub Actions (RECOMMANDÉ)

### Étapes pour tester maintenant :

1. **Pusher le code sur GitHub** (si pas encore fait)
2. **Créer un Service Principal via Azure Portal** (plus simple que CLI)
3. **Configurer les secrets GitHub**  
4. **Lancer le workflow de test**

### Créer Service Principal via Azure Portal :

1. Allez sur https://portal.azure.com
2. **Azure Active Directory** > **App registrations** > **New registration**
3. Nom: `github-actions-sp`
4. **Register**
5. Notez l'**Application (client) ID**
6. **Certificates & secrets** > **New client secret**  
7. Notez la **Value** du secret
8. **Subscriptions** > Votre subscription > **Access control (IAM)**
9. **Add role assignment** > **Contributor** > Assignez à votre app

### Format du secret AZURE_CREDENTIALS :
```json
{
  "clientId": "VOTRE_CLIENT_ID",
  "clientSecret": "VOTRE_CLIENT_SECRET", 
  "subscriptionId": "6df1bf9f-c8e8-4c71-aeb6-7d691adf418b",
  "tenantId": "19e51c11-d919-4a98-899d-9b9dc33f4e04"
}
```

## 🛠️ Option 2: Test Terraform local (en cours)

En attendant que Terraform soit installé localement...

## ⚡ Action immédiate recommandée

**Testons via GitHub Actions** qui est la méthode finale pour le prof :

1. Créez le Service Principal via Azure Portal (5 min)
2. Configurez les secrets GitHub (2 min)  
3. Lancez le workflow de test (10 min)
4. Validez le déploiement complet (5 min)

**Total : 22 minutes pour un test complet !**

Voulez-vous qu'on procède avec GitHub Actions maintenant ?