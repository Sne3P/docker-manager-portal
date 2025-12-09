# 🚀 Container Management Platform

Plateforme de gestion de conteneurs Docker avec déploiement direct Azure.

## ⚡ Déploiement ULTRA-RAPIDE (1 commande)

```powershell
# Connectez-vous à Azure
az login

# Déployez tout en 1 fois
.\deploy-minimal.ps1
```

**C'est tout !** 🎉 

## 🌐 Résultat (2-3 minutes)

- **Frontend :** `https://container-simple-web.azurewebsites.net`
- **API :** `https://container-simple-api.azurewebsites.net/api/health`

## 🧹 Nettoyage

```powershell
az group delete --name rg-container-simple --yes --no-wait
```

## ✨ Features

### Core Functionality
- **Multi-tenant Architecture**: Isolated container management per client
- **Role-Based Access Control**: Admin and client user roles
- **Real-time Container Operations**: Create, start, stop, delete containers
- **Container Monitoring**: Live status, logs, and resource usage
- **Security-First Design**: JWT authentication, input validation

### Cloud-Native Features
- **Infrastructure as Code**: Complete Terraform Azure deployment
- **CI/CD Pipeline**: Automated testing, building, and deployment
- **Health Monitoring**: Built-in health checks and readiness probes
- **Scalable Architecture**: Azure App Services with auto-scaling
- **Production Database**: Azure PostgreSQL with SSL encryption

### Technical Stack
- **Backend**: Node.js, Express, TypeScript, Docker SDK
- **Frontend**: Next.js, React, Tailwind CSS, TypeScript  
- **Database**: PostgreSQL (Azure Flexible Server)
- **Infrastructure**: Azure App Service, Container Registry, Application Gateway
- **CI/CD**: GitHub Actions, Terraform

## 🚀 Quick Start

### 🎓 For Professor Evaluation

**Ultra-simple deployment (3 steps) :**

1. **Fork this repository**
2. **Configure 2 GitHub secrets:**
   - `AZURE_CREDENTIALS` (Azure service principal JSON)
   - `DB_ADMIN_PASSWORD` (secure database password)
3. **Push to main branch** → Automatic deployment! 🎉

📖 **Detailed instructions:** [DEPLOY-FOR-PROFESSOR.md](./DEPLOY-FOR-PROFESSOR.md)

### 💻 Local Development
```bash
git clone https://github.com/Sne3P/docker-manager-portal.git
cd docker-manager-portal
docker-compose up -d --build
open http://localhost
```

**Default Credentials**:
- **Admin**: `admin` / `admin123`  
- **Client**: `client1` / `client123`

## ☁️ **Professor Deployment (3 steps)**

### 🎓 **Ultra-Simple for Evaluation:**

1. **Fork** this repository
2. **Add 2 GitHub Secrets:**
   - `AZURE_CREDENTIALS` → Create via [Azure Cloud Shell](https://shell.azure.com): 
     ```bash
     az ad sp create-for-rbac --name "github-sp" --role contributor --scopes "/subscriptions/$(az account show --query id -o tsv)" --sdk-auth
     ```
   - `DB_ADMIN_PASSWORD` → Any secure password (e.g., `SecurePass123!`)
3. **Push to main** → Automatic deployment! 🚀

**Result:** Complete Azure infrastructure + running application in 15 minutes!

### 🔧 **What Gets Deployed Automatically:**
- ✅ Azure App Services (Frontend + Backend)
- ✅ PostgreSQL Database with SSL
- ✅ Container Registry + Images  
- ✅ Application Gateway + Load Balancing
- ✅ Health monitoring + Auto-scaling
- Web Dashboard

## Services

- **Backend**: Node.js API (port 5000)
- **Frontend**: Next.js Web App (port 3000)
- **Nginx**: Reverse Proxy (port 80)
- **Redis**: Cache & Sessions (port 6379)

## Container Operations

Create predefined services:
- Nginx Web Server
- Node.js App
- Python App  
- Database Service

## Development

Backend:
```bash
cd dashboard-backend && npm run dev
```

Frontend:
```bash
cd dashboard-frontend && npm run dev
```
