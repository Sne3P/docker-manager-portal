# 🚀 Portail Cloud Container

Plateforme de gestion de containers Azure avec interface web moderne. Déploiement automatisé sur Azure Container Apps avec PostgreSQL, authentification JWT et dashboard temps réel.

## ⚡ Déploiement en 1 Commande

```bash
bash ./deploy-optimized.sh
```

**C'est tout !** Le script configure automatiquement tous les outils et déploie l'infrastructure complète.

## 🛠️ Prérequis

- **Compte Azure** (avec permissions Contributor)
- **Docker Desktop** installé et démarré
- **Bash** (Windows/Linux/macOS)

> ⚠️ **Aucune configuration manuelle nécessaire** - tout est automatique !

## 📋 Que fait le script ?

### 🔧 Configuration automatique
- ✅ Installe Azure CLI, Terraform, jq si manquants
- ✅ Vous connecte à Azure (`az login`)
- ✅ Génère un ID unique depuis votre email
- ✅ Enregistre les providers Azure requis
- ✅ Démarre Docker si nécessaire

### 🏗️ Infrastructure déployée
- 🗃️ **Base de données** PostgreSQL (mots de passe auto-générés)
- 🐳 **Container Registry** Azure (ACR)
- 🌐 **Container Apps** Backend + Frontend
- 📊 **Monitoring** Log Analytics
- 🔒 **Sécurité** HTTPS automatique + JWT

### 🎯 Résultat final
- **URLs publiques HTTPS** fonctionnelles
- **Base de données** initialisée avec utilisateurs test
- **Applications** complètement opérationnelles
- **Durée** : 5-8 minutes | **Coût** : ~2-3€/jour

## 🐛 Debugging & Maintenance

### 🧹 Redémarrer à zéro
```bash
bash ./deploy-optimized.sh --clean
```
Supprime toutes les ressources Azure et redéploie proprement.

### 🔄 Après une erreur
```bash
# Relancer directement après une erreur
bash ./deploy-optimized.sh
```
Le script gère automatiquement les états existants et reprend où il s'est arrêté.

### 📊 Validation complète
```powershell
.\validate-deployment-clean.ps1
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Frontend      │◄───┤    Backend      │
│   (Next.js)     │    │   (Node.js)     │
│   Container App │    │   Container App │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┼──────────────┐
                                 │              │
              ┌─────────────────┐│   ┌─────────────────┐
              │  PostgreSQL     ││   │ Container       │
              │  Database       ││   │ Registry (ACR)  │
              └─────────────────┘│   └─────────────────┘
                                 │
              ┌─────────────────┐│
              │ Log Analytics   ││
              │ Workspace       ││
              └─────────────────┘│
```

## 🔑 Utilisateurs de Test Créés

| Rôle | Email | Mot de passe |
|------|--------|---------------|
| Admin | `admin@portail-cloud.com` | `admin123` |
| Client | `client1@portail-cloud.com` | `client123` |
| Client | `client2@portail-cloud.com` | `client123` |
| Client | `client3@portail-cloud.com` | `client123` |

## 🛠️ Technologies

- **Frontend** : Next.js 14, TypeScript, Tailwind CSS
- **Backend** : Node.js, Express, TypeScript
- **Base de données** : PostgreSQL Flexible Server
- **Infrastructure** : Azure Container Apps, Terraform
- **Monitoring** : Azure Log Analytics
- **CI/CD** : Scripts Bash optimisés

## 📁 Structure Projet

```
portail-cloud-container/
├── 🚀 deploy-optimized.sh       # Script de déploiement principal
├── 🔧 setup-prerequisites.sh    # Configuration automatique des outils
├── 📊 validate-deployment-clean.ps1  # Script de validation
├── 🌐 dashboard-frontend/       # Application Next.js
├── ⚙️  dashboard-backend/        # API Node.js
├── 🏗️ terraform/azure/          # Infrastructure Terraform
├── 🐳 docker-images/           # Images Docker de démonstration
└── 🔧 nginx/                   # Configuration Nginx
```

## 🎯 Endpoints Utiles

Une fois déployé :
- **Frontend** : `https://frontend-[votre-id].azurecontainerapps.io`
- **Backend API** : `https://backend-[votre-id].azurecontainerapps.io/api`
- **Health Check** : `https://backend-[votre-id].azurecontainerapps.io/api/health`
- **Database Status** : `https://backend-[votre-id].azurecontainerapps.io/api/health/db-status`

## ❓ Problèmes Courants

| Problème | Solution |
|----------|----------|
| Docker pas démarré | Lancer Docker Desktop manuellement |
| Erreur Azure CLI | `az logout` puis relancer le script |
| Timeout Terraform | Relancer `bash ./deploy-optimized.sh` |
| Conflit de ressources | `bash ./deploy-optimized.sh --clean` |

## 🏷️ Versions

- **Terraform** : 1.5.7
- **Azure CLI** : Dernière version
- **Node.js** : 18 LTS
- **Next.js** : 14.x

---

💡 **Astuce** : Le système utilise votre email Azure pour générer un ID unique. Toutes les ressources seront nommées `resource-[vos-8-premiers-chars]`.
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