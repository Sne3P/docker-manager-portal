#!/bin/bash

# Script de déploiement automatique pour le Portail Cloud Container
# Usage: ./deploy-auto.sh [unique_id]

set -e

UNIQUE_ID=${1:-$(whoami)}
RESOURCE_GROUP="rg-container-manager-${UNIQUE_ID}"
ACR_NAME="acr${UNIQUE_ID}"

echo "🚀 Déploiement automatique Portail Cloud Container"
echo "📋 ID unique: ${UNIQUE_ID}"

# 1. Build et push des images Docker
echo "🐳 Build et push des images Docker..."

# Login Azure Container Registry
az acr login --name ${ACR_NAME}

# Build backend avec les dernières corrections
docker build -t ${ACR_NAME}.azurecr.io/container-manager-backend:real-azure-msi ./dashboard-backend
docker push ${ACR_NAME}.azurecr.io/container-manager-backend:real-azure-msi

# Build frontend avec configuration API correcte
docker build -t ${ACR_NAME}.azurecr.io/dashboard-frontend:api-fixed ./dashboard-frontend  
docker push ${ACR_NAME}.azurecr.io/dashboard-frontend:api-fixed

echo "✅ Images Docker déployées"

# 2. Déploiement Terraform
echo "🏗️ Déploiement Terraform..."
cd terraform/azure

# Initialisation (si nécessaire)
terraform init

# Planification
terraform plan -var="unique_id=${UNIQUE_ID}" -out=tfplan

# Application
terraform apply tfplan

echo "✅ Infrastructure déployée"

# 3. Vérification des URLs
echo "🌐 URLs de l'application:"
BACKEND_URL=$(terraform output -raw backend_url)
FRONTEND_URL=$(terraform output -raw frontend_url)

echo "Backend:  ${BACKEND_URL}"
echo "Frontend: ${FRONTEND_URL}"

# 4. Test de connectivité
echo "🧪 Test de connectivité..."
curl -f "${BACKEND_URL}/health" || echo "❌ Backend non accessible"
curl -f "${FRONTEND_URL}" || echo "❌ Frontend non accessible"

echo "🎉 Déploiement terminé !"