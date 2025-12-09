# Container Management Platform 🐳

[![Deploy to Azure](https://github.com/Sne3P/docker-manager-portal/actions/workflows/deploy.yml/badge.svg)](https://github.com/Sne3P/docker-manager-portal/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Azure](https://img.shields.io/badge/Azure-0078D4?logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)

> **Production-ready multi-tenant container management platform with automated cloud deployment**

A secure, scalable platform for managing Docker containers across multiple clients with role-based access control, built with modern cloud-native technologies.

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Azure Deployment](#-azure-deployment)
- [Local Development](#-local-development)
- [API Documentation](#-api-documentation)
- [Security](#-security)

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

## ☁️ Azure Deployment

### Automated Deployment (Recommended)

1. **Fork this repository** to your GitHub account

2. **Configure GitHub Secrets**:
   ```
   AZURE_CREDENTIALS      # Azure service principal JSON
   AZURE_RESOURCE_GROUP   # Target resource group name  
   AZURE_REGISTRY_NAME    # Container registry name
   AZURE_REGISTRY_USERNAME # Registry admin username
   AZURE_REGISTRY_PASSWORD # Registry admin password
   DB_ADMIN_PASSWORD      # Database password (secure)
   ```

3. **Push to main branch** - Deployment starts automatically!

### Manual Deployment

```bash
# 1. Azure Login
az login

# 2. Deploy Infrastructure  
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply

# 3. Get deployment URLs
terraform output backend_url
terraform output frontend_url
```

## 🔒 Security & Production Ready

- **Infrastructure as Code**: Complete Terraform deployment
- **CI/CD Pipeline**: Automated testing and deployment
- **JWT Authentication**: Secure token-based authentication  
- **Role-Based Access**: Admin vs Client permissions
- **Health Monitoring**: Built-in health checks
- **Database Security**: Azure PostgreSQL with SSL
- **Container Security**: Azure Container Registry
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
