#!/bin/bash
# =============================================================
# DÉPLOIEMENT PORTAIL CLOUD UNIVERSEL
# =============================================================
# Script portable pour toutes machines/OS/CI-CD
# Prérequis: Docker uniquement
# =============================================================

set -e

echo "🚀 PORTAIL CLOUD - DÉPLOIEMENT UNIVERSEL"
echo "========================================"
echo "Machine: $(uname -a 2>/dev/null || echo 'Windows')"
echo "Docker: $(docker --version)"
echo ""

# Configuration
IMAGE_NAME="portail-deploy"
VOLUME_NAME="portail-azure-credentials"

echo "🔨 Build de l'image de déploiement..."
docker build -f Dockerfile.simple -t $IMAGE_NAME .

if [ $? -eq 0 ]; then
    echo "✅ Image construite avec succès"
else
    echo "❌ Échec du build"
    exit 1
fi

echo ""
echo "🚀 Lancement du déploiement automatique..."
echo "========================================="

# Création du volume pour persistance des credentials Azure
docker volume create $VOLUME_NAME 2>/dev/null || true

# Lancement du déploiement complet
docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$(pwd):/workspace" \
    -v $VOLUME_NAME:/root/.azure \
    $IMAGE_NAME \
    ./deploy-optimized.sh "$@"

echo ""
echo "🎉 Déploiement terminé!"
echo "📋 Image disponible: $IMAGE_NAME"
echo "💾 Credentials Azure sauvés dans: $VOLUME_NAME"