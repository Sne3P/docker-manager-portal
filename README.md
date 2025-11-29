# Container Manager Platform 🚀

![Platform Logo](https://img.shields.io/badge/Container-Manager-blue?style=for-the-badge&logo=docker)
[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

## 📋 Description

**SaaS Container Manager** est une plateforme cloud complète de gestion de services Docker multi-clients développée avec Express.js (backend) et Next.js (frontend). La plateforme permet aux entreprises de gérer leurs conteneurs Docker de manière centralisée avec une interface moderne et des fonctionnalités avancées de monitoring.

## 🏗️ Architecture

```
Container Manager Platform
├── 📱 Dashboard Frontend (Next.js + TypeScript)
├── 🔌 Backend API (Express.js + TypeScript)
├── 🛠️ Services de démonstration (API, Web, Worker)
├── 🚀 Infrastructure Azure (Terraform)
├── 📊 Monitoring (Prometheus + Grafana)
└── 🔄 CI/CD (GitHub Actions)
```

### Composants principaux

- **Dashboard Frontend**: Interface utilisateur moderne avec Next.js et Tailwind CSS
- **Backend API**: API RESTful avec Express.js et intégration Docker
- **Services Multi-tenants**: Gestion isolée des conteneurs par client
- **Infrastructure Azure**: Déploiement automatisé avec Terraform
- **Monitoring Complet**: Métriques et logs centralisés
- **CI/CD Pipeline**: Déploiement automatique avec GitHub Actions

## 🎯 Vision du projet

Le **SaaS Container Manager** est une plateforme cloud permettant de gérer des applications tournant dans des containers Docker pour plusieurs clients. Chaque client dispose de ses propres containers représentant ses services SaaS, tandis que l'administrateur peut gérer l'ensemble de l'infrastructure.

## ✨ Fonctionnalités

### 🎯 Gestion des conteneurs
- ✅ Création, démarrage, arrêt et suppression de conteneurs
- ✅ Monitoring en temps réel des ressources (CPU, RAM, réseau)
- ✅ Logs en direct avec interface web
- ✅ Gestion des volumes et réseaux Docker
- ✅ Isolation multi-tenant complète

### 👥 Multi-tenant
- ✅ Séparation stricte des données clients
- ✅ Authentification JWT sécurisée
- ✅ Rôles et permissions granulaires
- ✅ Quotas de ressources par client
- ✅ Facturation basée sur l'utilisation

### 📊 Monitoring et observabilité
- ✅ Métriques Prometheus intégrées
- ✅ Dashboards Grafana personnalisés
- ✅ Alertes automatisées (Slack, Email)
- ✅ Logs centralisés avec Fluentd
- ✅ Santé des services en temps réel

### 🚀 DevOps et déploiement
- ✅ Infrastructure as Code avec Terraform
- ✅ CI/CD automatisé avec GitHub Actions
- ✅ Déploiement Azure complet
- ✅ Sauvegardes automatiques
- ✅ Mise à jour en continu

## 🛠️ Stack technique

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js avec TypeScript
- **Base de données**: Redis (cache) + Azure Cosmos DB (production)
- **Authentification**: JWT avec refresh tokens
- **Docker**: Dockerode SDK pour l'intégration Docker
- **WebSocket**: Socket.IO pour les mises à jour temps réel

### Frontend
- **Framework**: Next.js 14 avec TypeScript
- **UI**: Tailwind CSS + Headless UI
- **State Management**: React Query + Zustand
- **Charts**: Chart.js / Recharts
- **WebSocket**: Socket.IO client

### Infrastructure
- **Cloud Provider**: Microsoft Azure
- **Orchestration**: Docker Compose
- **Monitoring**: Prometheus + Grafana
- **Reverse Proxy**: Nginx
- **CI/CD**: GitHub Actions
- **IaC**: Terraform

## 🚀 Installation rapide

### Prérequis
- Node.js 18+
- Docker & Docker Compose
- Azure CLI (pour déploiement)
- Terraform (pour infrastructure)

### Installation locale

```bash
# 1. Cloner le projet
git clone https://github.com/yourusername/container-manager-platform.git
cd container-manager-platform

# 2. Installer les dépendances
npm run install:all

# 3. Configurer l'environnement
cp .env.example .env
# Éditer .env avec vos configurations

# 4. Lancer en développement
npm run dev

# 5. Accéder aux services
# Dashboard: http://localhost:3000
# API: http://localhost:5000
# Demo API: http://localhost:3001
# Demo Web: http://localhost:8080
```

### Déploiement production

```bash
# 1. Configuration production
cp .env.production.example .env.production
# Configurer les variables d'environnement

# 2. Déployer l'infrastructure Azure
npm run deploy:azure

# 3. Lancer les services en production
npm run prod

# 4. Vérifier la santé des services
npm run health
```

## 📁 Structure du projet

```
portail-cloud-container/
├── 📱 dashboard-frontend/          # Interface utilisateur Next.js
│   ├── src/
│   │   ├── components/            # Composants React réutilisables
│   │   ├── hooks/                 # Hooks React personnalisés
│   │   ├── pages/                 # Pages Next.js
│   │   ├── styles/                # Styles Tailwind CSS
│   │   ├── types/                 # Définitions TypeScript
│   │   └── utils/                 # Utilitaires et helpers
│   └── package.json
├── 🔌 dashboard-backend/           # API Express.js
│   ├── src/
│   │   ├── controllers/           # Contrôleurs API
│   │   ├── middleware/            # Middlewares Express
│   │   ├── routes/                # Routes API
│   │   ├── services/              # Services métier
│   │   ├── types/                 # Types TypeScript
│   │   └── utils/                 # Utilitaires
│   └── package.json
├── 🛠️ services/                    # Services de démonstration
│   ├── api-service/               # Service API Node.js
│   ├── web-service/               # Service Web Nginx
│   └── worker-service/            # Service Worker
├── 🚀 infra/                       # Infrastructure Terraform
│   ├── main.tf                    # Configuration principale
│   ├── variables.tf               # Variables Terraform
│   ├── outputs.tf                 # Sorties Terraform
│   └── cloud-init.yml             # Configuration VM
├── 📊 monitoring/                  # Configuration monitoring
│   ├── prometheus/                # Configuration Prometheus
│   ├── grafana/                   # Dashboards Grafana
│   └── nginx/                     # Configuration Nginx
├── 🔄 .github/workflows/          # CI/CD GitHub Actions
├── 📜 scripts/                     # Scripts de déploiement
├── docker-compose.yml             # Environnement développement
├── docker-compose.prod.yml        # Environnement production
└── package.json                   # Configuration monorepo
```

## 🔧 Configuration

### Variables d'environnement

#### Backend (.env)
```bash
# API Configuration
NODE_ENV=development
PORT=5000
JWT_SECRET=your-jwt-secret-key
JWT_REFRESH_SECRET=your-refresh-secret-key

# Database
REDIS_URL=redis://localhost:6379

# Docker
DOCKER_SOCKET=/var/run/docker.sock

# Azure (Production)
AZURE_STORAGE_CONNECTION_STRING=your-storage-connection
AZURE_KEY_VAULT_URL=your-keyvault-url
```

#### Frontend (next.config.js)
```javascript
const nextConfig = {
  env: {
    API_BASE_URL: process.env.API_BASE_URL || 'http://localhost:5000',
    WEBSOCKET_URL: process.env.WEBSOCKET_URL || 'http://localhost:5000',
  }
}
```

## 📊 Monitoring

### Métriques disponibles
- **Système**: CPU, mémoire, disque, réseau
- **Conteneurs**: État, ressources, logs
- **Application**: Requêtes API, temps de réponse, erreurs
- **Business**: Utilisateurs actifs, conteneurs par client

### Dashboards Grafana
- **Vue d'ensemble système**: Métriques globales de la plateforme
- **Monitoring conteneurs**: État et performances des conteneurs
- **Métriques applicatives**: Performance de l'API et du frontend
- **Analyse business**: KPIs et métriques métier

### Alertes configurées
- Utilisation CPU > 80%
- Utilisation mémoire > 85%
- Conteneur en erreur
- API non disponible
- Disque plein > 90%

## 🔒 Sécurité

### Authentification et autorisation
- JWT avec refresh tokens
- Rôles granulaires (Super Admin, Admin, User)
- Rate limiting sur les API
- Validation stricte des entrées

### Isolation multi-tenant
- Séparation des données par tenant
- Réseaux Docker isolés
- Quotas de ressources
- Audit trail complet

### Infrastructure sécurisée
- HTTPS obligatoire en production
- Azure Key Vault pour les secrets
- Pare-feu Azure configuré
- Sauvegarde chiffrée

## 🧪 Tests

```bash
# Tests unitaires
npm run test

# Tests backend uniquement
npm run test:backend

# Tests frontend uniquement
npm run test:frontend

# Coverage
npm run test:coverage

# Tests e2e
npm run test:e2e
```

## 📈 Performance

### Optimisations backend
- Cache Redis pour les données fréquemment accédées
- Pagination automatique des résultats
- Connection pooling pour Docker
- Compression gzip

### Optimisations frontend
- Server-side rendering avec Next.js
- Code splitting automatique
- Optimisation des images
- Service Worker pour le cache

### Monitoring performances
- Métriques APM intégrées
- Profiling automatique
- Alertes sur les seuils de performance
- Optimisation continue

## 🚀 Déploiement Azure

### Architecture cloud
```
Azure Resource Group
├── Virtual Machine (Ubuntu 20.04)
├── Container Registry (ACR)
├── Log Analytics Workspace
├── Key Vault (secrets)
├── Storage Account (backups)
├── Network Security Group
└── Public IP with DNS
```

### Processus de déploiement
1. **Infrastructure**: Terraform provisionne les ressources Azure
2. **Configuration**: Cloud-init configure la VM
3. **Services**: Docker Compose lance les conteneurs
4. **Monitoring**: Prometheus et Grafana activés
5. **CI/CD**: GitHub Actions automatise les mises à jour

## 🤝 Contribution

### Processus de développement
1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Committer les changements (`git commit -m 'Add AmazingFeature'`)
4. Pousser la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Standards de code
- ESLint et Prettier configurés
- Hooks de pre-commit avec Husky
- Tests obligatoires pour les nouvelles fonctionnalités
- Documentation mise à jour

## 📞 Support

### Documentation
- [API Documentation](./docs/api.md)
- [Deployment Guide](./docs/deployment.md)
- [Troubleshooting](./docs/troubleshooting.md)

### Contact
- 📧 Email: support@container-manager.com
- 💬 Slack: [#container-manager](https://your-workspace.slack.com)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/container-manager-platform/issues)

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](./LICENSE) pour plus de détails.

## 🙏 Remerciements

- [Docker](https://www.docker.com/) pour la containerisation
- [Next.js](https://nextjs.org/) pour le framework frontend
- [Express.js](https://expressjs.com/) pour l'API backend
- [Azure](https://azure.microsoft.com/) pour l'infrastructure cloud
- [Prometheus](https://prometheus.io/) et [Grafana](https://grafana.com/) pour le monitoring

---

<div align="center">
  <strong>Container Manager Platform</strong><br>
  Développé avec ❤️ pour simplifier la gestion Docker multi-tenant
</div>

## 🏗️ Architecture technique détaillée

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud Infrastructure              │
├─────────────────────────────────────────────────────────────┤
│  Resource Group                                             │
│  ├─ VM Linux (Docker Host)                                 │
│  ├─ Azure Container Registry (ACR)                         │
│  ├─ Log Analytics Workspace                                │
│  └─ Virtual Network + Security Groups                      │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                 Application Layer                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌──────────────────────────────┐   │
│  │  Frontend       │    │  Backend API                 │   │
│  │  (Next.js)      │◄──►│  (Express + TypeScript)      │   │
│  │                 │    │                              │   │
│  │  • Admin Panel  │    │  • Docker Management        │   │
│  │  • Client Panel │    │  • Multi-tenant Auth        │   │
│  │  • Monitoring   │    │  • Container Operations     │   │
│  └─────────────────┘    └──────────────────────────────┘   │
│                                     │                       │
│                                     ▼                       │
│            ┌─────────────────────────────────────┐          │
│            │         Docker Engine               │          │
│            │                                     │          │
│            │  ┌─────────┐  ┌─────────┐  ┌──────┐ │          │
│            │  │Client A │  │Client B │  │ ...  │ │          │
│            │  │Services │  │Services │  │      │ │          │
│            │  └─────────┘  └─────────┘  └──────┘ │          │
│            └─────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Structure du projet

```
portail-cloud-container/
├── infra/                          # Infrastructure as Code (Terraform)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
├── dashboard-backend/              # API Express + TypeScript
│   ├── src/
│   ├── Dockerfile
│   ├── package.json
│   └── README.md
├── dashboard-frontend/             # Interface Next.js + TypeScript
│   ├── src/
│   ├── Dockerfile
│   ├── package.json
│   └── README.md
├── services/                       # Services clients exemples
│   ├── service-api/               # API de démonstration
│   ├── service-web/               # Site web Nginx
│   └── service-worker/            # Worker avec logs
├── .github/                        # CI/CD GitHub Actions
│   └── workflows/
├── docker-compose.yml              # Orchestration locale
├── docker-compose.prod.yml         # Orchestration production
└── README.md                       # Ce fichier
```

## 🚀 Déploiement rapide

### Prérequis

- Azure CLI installé et connecté
- Terraform >= 1.0
- Docker Desktop
- Node.js >= 18
- Git

### 1. Infrastructure

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 2. Développement local

```bash
# Installation des dépendances
npm run install:all

# Lancement du stack complet
docker-compose up -d

# Accès au dashboard
open http://localhost:3000
```

### 3. Déploiement production

Le déploiement est automatique via GitHub Actions lors des pushs sur `main`.

## 👤 Utilisation

### Accès Admin
- URL: `https://votre-domain.com/admin`
- Fonctionnalités: Gestion complète de tous les containers et clients

### Accès Client
- URL: `https://votre-domain.com/client`
- Fonctionnalités: Gestion de ses propres containers uniquement

### Services disponibles
- **API Demo**: Service REST simple pour tests
