# 🚀 Portail Cloud Container

Application web moderne pour gérer vos conteneurs Docker avec déploiement automatisé sur Azure.

## ✨ Fonctionnalités

- **Dashboard temps réel** : Surveillance des conteneurs en direct
- **Interface multi-rôles** : Séparation admin/client
- **Métriques avancées** : CPU, mémoire, réseau, stockage  
- **Actions conteneurs** : Start/Stop/Restart en temps réel
- **Déploiement automatique** : Infrastructure et applications en une commande
- **Base de données auto-initialisée** : Schémas créés automatiquement
- **Déploiement Azure** : Infrastructure as Code avec Terraform
- **API sécurisée** : Backend Node.js + JWT

## 🏗️ Architecture

```
├── dashboard-frontend/     # Next.js + Tailwind CSS
├── dashboard-backend/      # Node.js + Express API
├── database/              # PostgreSQL + init script
├── terraform/azure/       # Infrastructure Azure
├── deploy-simple.ps1      # Déploiement automatisé
└── docker-compose.yml     # Développement local
```

## 🚀 Déploiement Azure (Recommandé)

### Prérequis
- Azure CLI installé et connecté (`az login`)
- Docker Desktop démarré
- PowerShell 5.1+

### Déploiement Automatique Complet
```powershell
# Déploiement en une commande
.\deploy-final.ps1

# Validation post-déploiement (optionnel)
.\validate-deployment-clean.ps1 -Verbose
```

### Ce qui est automatisé :
✅ **Infrastructure Azure** (Terraform)
- PostgreSQL Flexible Server
- Azure Container Apps Environment  
- Azure Container Registry
- Log Analytics Workspace

✅ **Applications**
- Build et push des images Docker
- Déploiement backend/frontend
- Configuration des variables d'environnement
- URLs automatiquement configurées

✅ **Base de Données**
- Initialisation automatique des schémas
- Création des utilisateurs par défaut
- Configuration des indexes et triggers

✅ **Validation**
- Tests de connectivité
- Vérification de l'authentification
- Validation des endpoints API

Le script fait tout automatiquement :
- ✅ Détecte votre compte Azure
- ✅ Installe Terraform si nécessaire  
- ✅ Crée l'infrastructure Azure
- ✅ Déploie l'application
- ✅ Affiche les URLs d'accès

### Ressources créées
- **Resource Group** : `portail-cloud-dev-rg`
- **Container Apps** : Environnement serverless
- **Log Analytics** : Monitoring intégré
- **Région** : France Central (optimal)

## 🔧 Développement local (Optionnel)

```bash
# Pour développer en local
docker-compose up -d

# Accès local
Frontend: http://localhost:3000
Backend: http://localhost:5000
```

## 👥 Comptes par défaut

- **Admin** : admin@portail-cloud.com / admin123
- **Client** : client1@portail-cloud.com / client123

## 🧹 Nettoyage Azure

```powershell
# Supprimer toutes les ressources Azure
az group delete --name portail-cloud-dev-rg --yes
```

## 📊 Stack technique

- **Frontend** : Next.js, TypeScript, Tailwind CSS
- **Backend** : Node.js, Express, Socket.io
- **Database** : PostgreSQL 15
- **Cloud** : Azure Container Apps, Terraform
- **DevOps** : Infrastructure as Code, déploiement automatisé

## 🎯 Avantages Azure

- **Serverless** : Scaling automatique 0-N instances
- **Économique** : Pay-per-use, gratuit avec Azure Student  
- **Sécurisé** : HTTPS, isolation réseau
- **Monitoring** : Logs et métriques intégrés
- **Simple** : Un seul script pour tout déployer

---

> **Prêt à déployer ?** Lancez `.\deploy-simple.ps1` et votre app sera en ligne en quelques minutes ! 🎉