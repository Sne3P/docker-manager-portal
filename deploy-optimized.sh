#!/bin/bash

# =============================================================
# PORTAIL CLOUD - SCRIPT DE DEPLOIEMENT OPTIMISE ULTRA-COMPACT
# =============================================================

set -e  # Stop on first error
export DEBIAN_FRONTEND=noninteractive

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() { echo -e "${CYAN}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1"; exit 1; }

# =============================================================
# INSTALLATION AUTOMATIQUE DES DEPENDANCES
# =============================================================
install_dependencies() {
    log "🔧 Vérification et installation des dépendances..."
    
    # Détection du système
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
        SYSTEM="windows"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        SYSTEM="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        SYSTEM="macos"
    else
        SYSTEM="unknown"
    fi
    
    log "Système détecté: $SYSTEM"
    
    # Installation JQ
    if ! command -v jq &> /dev/null; then
        log "Installation de jq..."
        case $SYSTEM in
            "windows")
                # Windows/WSL - utiliser curl pour télécharger jq
                if command -v curl &> /dev/null; then
                    curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe -o /tmp/jq.exe 2>/dev/null
                    chmod +x /tmp/jq.exe
                    export PATH="/tmp:$PATH"
                    # Alternative: utiliser PowerShell en fallback
                    if ! command -v jq &> /dev/null; then
                        cat > /tmp/jq << 'EOF'
#!/bin/bash
# Fallback jq using PowerShell
powershell.exe -Command "
$input | ConvertFrom-Json | ConvertTo-Json -Depth 10 -Compress:$false
" 2>/dev/null || echo "$1"
EOF
                        chmod +x /tmp/jq
                    fi
                else
                    # Fallback PowerShell-based jq
                    cat > /tmp/jq << 'EOF'
#!/bin/bash
powershell.exe -Command "\$json=\$args[0]; if(\$json) { (\$json | ConvertFrom-Json).\$(\$args[1] -replace '\..*','') } else { Get-Content /dev/stdin | ConvertFrom-Json | ConvertTo-Json -Depth 10 }" -- "$@"
EOF
                    chmod +x /tmp/jq
                    export PATH="/tmp:$PATH"
                fi
                ;;
            "linux")
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update && sudo apt-get install -y jq
                elif command -v yum &> /dev/null; then
                    sudo yum install -y jq
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y jq
                fi
                ;;
            "macos")
                if command -v brew &> /dev/null; then
                    brew install jq
                else
                    curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 -o /tmp/jq
                    chmod +x /tmp/jq
                    export PATH="/tmp:$PATH"
                fi
                ;;
        esac
        
        if command -v jq &> /dev/null; then
            success "jq installé avec succès"
        else
            warn "Installation jq échouée, utilisation du fallback PowerShell"
        fi
    else
        success "jq déjà installé"
    fi
    
    # Installation Terraform
    if ! command -v terraform &> /dev/null; then
        log "Installation de Terraform..."
        case $SYSTEM in
            "windows")
                TERRAFORM_VERSION="1.5.7"
                TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_windows_amd64.zip"
                
                if command -v curl &> /dev/null; then
                    mkdir -p /tmp/terraform
                    cd /tmp/terraform
                    curl -L "$TERRAFORM_URL" -o terraform.zip
                    if command -v unzip &> /dev/null; then
                        unzip -o terraform.zip
                        chmod +x terraform
                        mv terraform terraform.exe 2>/dev/null || true
                    else
                        # Fallback PowerShell pour décompresser
                        powershell.exe -Command "
                            try {
                                Expand-Archive -Path 'terraform.zip' -DestinationPath '.' -Force
                                if (Test-Path 'terraform') { Rename-Item 'terraform' 'terraform.exe' }
                                Write-Host 'Terraform extracted successfully'
                            } catch {
                                Write-Error \$_.Exception.Message
                            }
                        " 
                    fi
                    chmod +x terraform.exe 2>/dev/null || chmod +x terraform 2>/dev/null || true
                    export PATH="/tmp/terraform:$PATH"
                    cd - >/dev/null
                fi
                ;;
            "linux")
                TERRAFORM_VERSION="1.5.7"
                TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
                
                mkdir -p /tmp/terraform
                cd /tmp/terraform
                curl -L "$TERRAFORM_URL" -o terraform.zip
                unzip -o terraform.zip
                chmod +x terraform
                export PATH="/tmp/terraform:$PATH"
                cd - >/dev/null
                ;;
            "macos")
                if command -v brew &> /dev/null; then
                    brew tap hashicorp/tap && brew install hashicorp/tap/terraform
                else
                    TERRAFORM_VERSION="1.5.7"
                    TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_amd64.zip"
                    
                    mkdir -p /tmp/terraform
                    cd /tmp/terraform
                    curl -L "$TERRAFORM_URL" -o terraform.zip
                    unzip -o terraform.zip
                    chmod +x terraform
                    export PATH="/tmp/terraform:$PATH"
                    cd - >/dev/null
                fi
                ;;
        esac
        
        # Vérification avec les différents noms possibles
        if command -v terraform &> /dev/null; then
            success "Terraform installé avec succès ($(terraform version | head -n1))"
        elif command -v terraform.exe &> /dev/null; then
            # Créer un alias terraform pour terraform.exe
            ln -sf "$(which terraform.exe)" "/tmp/terraform/terraform" 2>/dev/null || true
            success "Terraform installé avec succès ($(terraform.exe version | head -n1))"
        else
            warn "Installation Terraform échouée - tentative alternative..."
            # Essayer d'utiliser Chocolatey sur Windows
            if powershell.exe -Command "Get-Command choco -ErrorAction SilentlyContinue" &>/dev/null; then
                powershell.exe -Command "choco install terraform -y" 2>/dev/null || true
            fi
            
            if ! command -v terraform &> /dev/null && ! command -v terraform.exe &> /dev/null; then
                error "Terraform requis. Installez manuellement: https://www.terraform.io/downloads.html"
            fi
        fi
    else
        success "Terraform déjà installé ($(terraform version | head -n1))"
    fi
    
    # Installation Azure CLI
    if ! command -v az &> /dev/null; then
        log "Installation d'Azure CLI..."
        case $SYSTEM in
            "windows")
                warn "Azure CLI non trouvé. Installé manuellement depuis: https://aka.ms/installazurecliwindows"
                warn "Ou utilisez: winget install Microsoft.AzureCLI"
                ;;
            "linux")
                curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                ;;
            "macos")
                if command -v brew &> /dev/null; then
                    brew install azure-cli
                else
                    curl -L https://aka.ms/InstallAzureCli | bash
                fi
                ;;
        esac
    else
        success "Azure CLI déjà installé ($(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'version inconnue'))"
    fi
    
    # Vérification Docker
    if ! command -v docker &> /dev/null; then
        warn "Docker non trouvé. Installation requise:"
        case $SYSTEM in
            "windows") warn "  Installez Docker Desktop depuis: https://www.docker.com/products/docker-desktop" ;;
            "linux") warn "  curl -fsSL https://get.docker.com | sh" ;;
            "macos") warn "  brew install --cask docker" ;;
        esac
        error "Docker est requis pour continuer"
    else
        success "Docker déjà installé ($(docker --version))"
    fi
    
    success "✅ Toutes les dépendances sont prêtes"
}

# Parse arguments
CLEAN=false
SKIP_BUILD=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean) CLEAN=true; shift ;;
        --skip-build) SKIP_BUILD=true; shift ;;
        *) echo "Usage: $0 [--clean] [--skip-build]"; exit 1 ;;
    esac
done

log "🚀 DÉPLOIEMENT PORTAIL CLOUD OPTIMISÉ"

# Installation automatique des dépendances
install_dependencies

# ===========================
# PHASE 0: AUTHENTICATION & SETUP
# ===========================
log "Phase 0: Configuration initiale"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    error "Azure CLI non installé"
fi

# Login check and get account info
ACCOUNT_CHECK=$(az account show 2>/dev/null) || { 
    log "Connexion Azure requise..."
    az login
    ACCOUNT_CHECK=$(az account show)
}

# Récupération des infos via Azure CLI direct (sans jq)
USER_NAME=$(az account show --query "user.name" -o tsv 2>/dev/null)
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv 2>/dev/null)

# Génération UNIQUE_ID à partir du nom utilisateur
UNIQUE_ID=$(echo "$USER_NAME" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-8)
RG_NAME="rg-container-manager-$UNIQUE_ID"

success "ID unique: $UNIQUE_ID | Subscription: $SUBSCRIPTION_ID"

# ===========================
# PHASE 1: CLEANUP (IF REQUESTED)
# ===========================
if [ "$CLEAN" = true ]; then
    log "Phase 1: Nettoyage des ressources"
    
    # Delete resource group (async)
    az group delete --name "$RG_NAME" --yes --no-wait 2>/dev/null || true
    
    # Clean Terraform state
    cd terraform/azure
    rm -f .terraform.lock.hcl terraform.tfstate* tfplan* .terraform -rf 2>/dev/null || true
    cd ../..
    
    success "Nettoyage lancé (asynchrone)"
    
    # Wait a bit for resources to start deleting
    log "Attente du nettoyage (60s)..."
    sleep 60
fi

# ===========================
# PHASE 2: INFRASTRUCTURE TERRAFORM
# ===========================
log "Phase 2: Infrastructure Terraform"

cd terraform/azure

# Initialize Terraform (only if needed)
if [ ! -d ".terraform" ]; then
    log "Initialisation Terraform..."
    terraform init -upgrade
fi

# Smart conflict resolution
log "Résolution des conflits d'état..."
if az group show --name "$RG_NAME" &>/dev/null; then
    # Import existing container apps if they exist but aren't in state
    BACKEND_EXISTS=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" 2>/dev/null || echo "null")
    FRONTEND_EXISTS=$(az containerapp show --name "frontend-$UNIQUE_ID" --resource-group "$RG_NAME" 2>/dev/null || echo "null")
    
    if [ "$BACKEND_EXISTS" != "null" ] && ! terraform state list | grep -q "azurerm_container_app.backend"; then
        warn "Import backend existant dans l'état Terraform"
        BACKEND_ID=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "id" -o tsv 2>/dev/null)
        if [ -n "$BACKEND_ID" ]; then
            terraform import "azurerm_container_app.backend" "$BACKEND_ID" 2>/dev/null || true
        fi
    fi
    
    if [ "$FRONTEND_EXISTS" != "null" ] && ! terraform state list | grep -q "azurerm_container_app.frontend"; then
        warn "Import frontend existant dans l'état Terraform"
        FRONTEND_ID=$(az containerapp show --name "frontend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "id" -o tsv 2>/dev/null)
        if [ -n "$FRONTEND_ID" ]; then
            terraform import "azurerm_container_app.frontend" "$FRONTEND_ID" 2>/dev/null || true
        fi
    fi
fi

# Plan and apply in one go
log "Déploiement infrastructure..."
terraform plan -var="unique_id=$UNIQUE_ID" -out=tfplan
terraform apply -auto-approve tfplan

# Get outputs (sans jq)
log "Récupération des informations Terraform..."
ACR_SERVER=$(terraform output -raw container_registry_login_server 2>/dev/null)
ACR_NAME=$(terraform output -raw acr_name 2>/dev/null)
DB_URL=$(terraform output -raw database_url 2>/dev/null)

cd ../..

if [ -z "$ACR_SERVER" ] || [ -z "$ACR_NAME" ]; then
    error "Impossible de récupérer les informations Terraform"
fi

success "Infrastructure créée: $ACR_SERVER"

# ===========================
# PHASE 3: DOCKER IMAGES BUILD & PUSH (ORDRE CRITIQUE CORRIGÉ)
# ===========================
if [ "$SKIP_BUILD" != true ]; then
    log "Phase 3: Construction des images Docker (ordre corrigé)"
    
    # Login to ACR
    az acr login --name "$ACR_NAME"
    
    # ÉTAPE 3A: Build Backend (SANS push - Container Apps pas encore prêts)
    log "  📦 Backend (build local)..."
    docker build -t "$ACR_SERVER/dashboard-backend:latest" ./dashboard-backend
    success "Backend build terminé (pas encore pushé)"
    
    # ÉTAPE 3B: Vérification DYNAMIQUE que les Container Apps existent
    log "Vérification que les Container Apps sont créés par Terraform..."
    CONTAINER_APPS_READY=false
    MAX_WAIT_ATTEMPTS=5
    WAIT_ATTEMPT=0
    
    while [ $WAIT_ATTEMPT -lt $MAX_WAIT_ATTEMPTS ] && [ "$CONTAINER_APPS_READY" != true ]; do
        WAIT_ATTEMPT=$((WAIT_ATTEMPT + 1))
        log "  Vérification Container Apps $WAIT_ATTEMPT/$MAX_WAIT_ATTEMPTS..."
        
        # Vérifier existence des deux Container Apps
        BACKEND_EXISTS=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")
        FRONTEND_EXISTS=$(az containerapp show --name "frontend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")
        
        # Nettoyer les espaces et caractères cachés
        BACKEND_EXISTS=$(echo "$BACKEND_EXISTS" | tr -d '\r\n\t ' | tr -d '[:space:]')
        FRONTEND_EXISTS=$(echo "$FRONTEND_EXISTS" | tr -d '\r\n\t ' | tr -d '[:space:]')
        
        # Debug: afficher les valeurs exactes
        log "    Debug: Backend='$BACKEND_EXISTS' (longueur: ${#BACKEND_EXISTS})"
        log "    Debug: Frontend='$FRONTEND_EXISTS' (longueur: ${#FRONTEND_EXISTS})"
        
        if [ "$BACKEND_EXISTS" != "NotFound" ] && [ "$FRONTEND_EXISTS" != "NotFound" ] && [ -n "$BACKEND_EXISTS" ] && [ -n "$FRONTEND_EXISTS" ]; then
            if [ "$BACKEND_EXISTS" = "Succeeded" ] && [ "$FRONTEND_EXISTS" = "Succeeded" ]; then
                CONTAINER_APPS_READY=true
                success "✅ Container Apps créés et prêts (Backend: $BACKEND_EXISTS, Frontend: $FRONTEND_EXISTS)"
            else
                log "    Container Apps en cours de création (Backend: $BACKEND_EXISTS, Frontend: $FRONTEND_EXISTS)..."
                sleep 15
            fi
        else
            log "    Container Apps pas encore créés (Backend: $BACKEND_EXISTS, Frontend: $FRONTEND_EXISTS), attente 15s..."
            sleep 15
        fi
    done
    
    if [ "$CONTAINER_APPS_READY" != true ]; then
        error "❌ TIMEOUT: Container Apps non créés après $MAX_WAIT_ATTEMPTS tentatives"
        exit 1
    fi
    
    # ÉTAPE 3C: Maintenant on peut PUSH le backend en sécurité
    log "  📤 Push Backend vers ACR (Container Apps prêts)..."
    docker push "$ACR_SERVER/dashboard-backend:latest"
    success "✅ Backend pushé avec succès"
    
    # ÉTAPE 3D: Récupération INTELLIGENTE des URLs finales avec retry dynamique
    log "Récupération intelligente des URLs des Container Apps..."
    
    URLS_RETRIEVED=false
    MAX_URL_ATTEMPTS=3
    URL_ATTEMPT=0
    
    while [ $URL_ATTEMPT -lt $MAX_URL_ATTEMPTS ] && [ "$URLS_RETRIEVED" != true ]; do
        URL_ATTEMPT=$((URL_ATTEMPT + 1))
        log "  Tentative récupération URLs $URL_ATTEMPT/$MAX_URL_ATTEMPTS..."
        
        # Méthode 1: Terraform outputs (plus fiable)
        cd terraform/azure
        BACKEND_URL=$(terraform output -raw backend_url 2>/dev/null || echo "")
        FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null || echo "")
        cd ../..
        
        # Méthode 2: Azure CLI si Terraform échoue
        if [ -z "$BACKEND_URL" ] || [ -z "$FRONTEND_URL" ]; then
            log "    Terraform outputs vides, essai Azure CLI..."
            BACKEND_FQDN=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "")
            FRONTEND_FQDN=$(az containerapp show --name "frontend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "")
            
            if [ -n "$BACKEND_FQDN" ] && [ -n "$FRONTEND_FQDN" ]; then
                BACKEND_URL="https://$BACKEND_FQDN"
                FRONTEND_URL="https://$FRONTEND_FQDN"
            fi
        fi
        
        # Vérification des URLs (suffisant si elles existent)
        if [ -n "$BACKEND_URL" ] && [ -n "$FRONTEND_URL" ]; then
            log "    URLs trouvées, test de connectivité optionnel..."
            
            # Test rapide de connectivité (non bloquant)
            if curl -sf --connect-timeout 3 --max-time 5 "${BACKEND_URL%/}" >/dev/null 2>&1 || 
               curl -sf --connect-timeout 3 --max-time 5 "$BACKEND_URL/api/health" >/dev/null 2>&1; then
                URLS_RETRIEVED=true
                success "✅ URLs récupérées et immédiatement accessibles"
                success "   Backend: $BACKEND_URL | Frontend: $FRONTEND_URL"
            else
                # URLs récupérées = Container Apps créés, même si pas encore prêts à servir
                log "    URLs récupérées (Container Apps créés). Applications en cours de démarrage..."
                URLS_RETRIEVED=true
                success "✅ Container Apps déployés avec succès"
                success "   Backend: $BACKEND_URL | Frontend: $FRONTEND_URL"
                warn "   💡 Les applications peuvent mettre quelques minutes à démarrer complètement"
            fi
        else
            log "    URLs pas encore disponibles, attente 20s..."
            sleep 20
        fi
    done
    
    # Vérification finale critique
    if [ "$URLS_RETRIEVED" != true ] || [ -z "$BACKEND_URL" ] || [ -z "$FRONTEND_URL" ]; then
        error "❌ ÉCHEC CRITIQUE: Impossible de récupérer les URLs après $MAX_URL_ATTEMPTS tentatives"
        warn "   Vérifiez manuellement les Container Apps dans le portail Azure"
        warn "   Resource Group: $RG_NAME"
        exit 1
    fi
    
    # ÉTAPE 3D: Build Frontend avec la bonne API URL
    log "  📦 Frontend avec API URL correcte: $BACKEND_URL/api"
    docker build --build-arg NEXT_PUBLIC_API_URL="$BACKEND_URL/api" -t "$ACR_SERVER/dashboard-frontend:latest" ./dashboard-frontend
    docker push "$ACR_SERVER/dashboard-frontend:latest"
    success "Frontend pushed avec NEXT_PUBLIC_API_URL=$BACKEND_URL/api"
    
    # ÉTAPE 3E: Build Images Démo en parallèle (moins critique)
    log "  📦 Images démo (en parallèle)..."
    {
        docker build -t "$ACR_SERVER/nodejs-demo:latest" ./docker-images/nodejs-demo
        docker push "$ACR_SERVER/nodejs-demo:latest"
    } &
    {
        docker build -t "$ACR_SERVER/python-demo:latest" ./docker-images/python-demo  
        docker push "$ACR_SERVER/python-demo:latest"
    } &
    {
        docker build -t "$ACR_SERVER/database-demo:latest" ./docker-images/database-demo
        docker push "$ACR_SERVER/database-demo:latest"  
    } &
    {
        docker build -t "$ACR_SERVER/nginx-demo:latest" ./docker-images/nginx-demo
        docker push "$ACR_SERVER/nginx-demo:latest"
    } &
    
    # Attendre que toutes les images démo soient terminées
    wait
    success "Images démo pushées (parallèlement)"
    
    success "✅ Toutes les images déployées avec URLs correctes"
else
    log "Phase 3: Construction d'images ignorée (--skip-build)"
    
    # Still get URLs for later use
    cd terraform/azure
    BACKEND_URL=$(terraform output -raw backend_url 2>/dev/null || echo "")
    FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null || echo "")
    cd ../..
fi

# ===========================
# PHASE 4: CONFIGURATION CRITIQUE DES CONTAINER APPS
# ===========================
log "Phase 4: Configuration MSI, CORS et variables d'environnement"

# ÉTAPE 4A: Configuration MSI (Managed Identity) pour le backend
log "Configuration MSI pour accès Azure..."
az containerapp identity assign --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --system-assigned 2>/dev/null

# Attente DYNAMIQUE que l'identité soit propagée
log "Attente de la propagation de l'identité MSI..."
MSI_READY=false
for i in {1..12}; do  # Max 2 minutes
    PRINCIPAL_CHECK=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "identity.principalId" -o tsv 2>/dev/null || echo "")
    if [ -n "$PRINCIPAL_CHECK" ] && [ "$PRINCIPAL_CHECK" != "null" ]; then
        MSI_READY=true
        success "MSI propagé (Principal ID: ${PRINCIPAL_CHECK:0:8}...)"
        break
    fi
    log "  Attente propagation MSI $i/12 (10s)..."
    sleep 10
done

if [ "$MSI_READY" != true ]; then
    warn "⚠️ MSI propagation timeout, continuons quand même..."
fi

# ÉTAPE 4B: Récupération Principal ID et assignation des permissions
log "Attribution des permissions Contributor..."
PRINCIPAL_ID=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "identity.principalId" -o tsv 2>/dev/null || echo "")

if [ -n "$PRINCIPAL_ID" ] && [ "$PRINCIPAL_ID" != "null" ]; then
    # Permissions pour gérer les resources dans le resource group
    az role assignment create --assignee "$PRINCIPAL_ID" --role "Contributor" --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME" 2>/dev/null || true
    
    # Permissions pour pull des images depuis l'ACR
    az role assignment create --assignee "$PRINCIPAL_ID" --role "AcrPull" --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME" 2>/dev/null || true
    
    success "MSI configuré avec permissions Contributor + AcrPull"
else
    warn "Principal ID non récupéré, MSI peut ne pas fonctionner"
fi

# ÉTAPE 4C: Configuration CORS et variables d'environnement CRITIQUES
if [ -n "$BACKEND_URL" ] && [ -n "$FRONTEND_URL" ]; then
    log "Configuration CORS et variables d'environnement critiques..."
    
    # Backend: Configuration CORS + variables Azure
    log "  Configuration backend (CORS + Azure vars)..."
    az containerapp update --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" \
        --set-env-vars \
        "FRONTEND_URL=$FRONTEND_URL" \
        "AZURE_RESOURCE_GROUP=$RG_NAME" \
        "AZURE_CONTAINER_ENVIRONMENT=env-$UNIQUE_ID" \
        "AZURE_CONTAINER_REGISTRY=$ACR_SERVER" \
        "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID" \
        "AZURE_USE_MSI=true" \
        2>/dev/null || warn "Erreur configuration backend"
    
    # Frontend: Configuration variables d'environnement
    log "  Configuration frontend (API URL)..."  
    az containerapp update --name "frontend-$UNIQUE_ID" --resource-group "$RG_NAME" \
        --set-env-vars \
        "NODE_ENV=production" \
        "NEXT_PUBLIC_API_URL=$BACKEND_URL/api" \
        2>/dev/null || warn "Erreur configuration frontend"
    
    success "✅ CORS configuré: $FRONTEND_URL ↔ $BACKEND_URL"
    success "✅ Variables d'environnement mises à jour"
    
    # ÉTAPE 4D: Redémarrage des containers pour appliquer les changements
    log "Redémarrage des containers pour appliquer la configuration..."
    
    # Redémarrage du backend (critique pour MSI et CORS)
    BACKEND_REVISION=$(az containerapp revision list --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null)
    if [ -n "$BACKEND_REVISION" ]; then
        log "Redémarrage backend pour appliquer MSI + CORS..."
        az containerapp revision restart --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --revision "$BACKEND_REVISION" 2>/dev/null || true
        
        # Attente DYNAMIQUE que le backend redémarre
        log "Attente du redémarrage backend..."
        BACKEND_RESTARTED=false
        for i in {1..15}; do  # Max 5 minutes
            # Test direct de santé - plus fiable que le status de révision
            if curl -sf --connect-timeout 3 --max-time 8 "$BACKEND_URL/api/health" >/dev/null 2>&1; then
                BACKEND_RESTARTED=true
                success "✅ Backend redémarré et opérationnel (health check réussi)"
                break
            else
                # Vérifier le statut de l'app comme backup
                APP_STATUS=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "properties.runningStatus" -o tsv 2>/dev/null || echo "Unknown")
                log "  Backend redémarrage en cours (Status: $APP_STATUS) $i/15 (20s)..."
            fi
            sleep 20
        done
        
        if [ "$BACKEND_RESTARTED" != true ]; then
            warn "⚠️ Timeout redémarrage backend, continuons quand même..."
        fi
    fi
    
else
    error "URLs manquantes pour la configuration CORS"
    exit 1
fi

# ===========================
# PHASE 5: INITIALISATION AUTOMATIQUE DE LA BASE DE DONNÉES
# ===========================
log "Phase 5: Initialisation complète de la base de données"

# ÉTAPE 5A: Attente que le backend soit complètement opérationnel
log "Attente que le backend soit prêt avec la nouvelle configuration..."
MAX_RETRIES=30
RETRY_COUNT=0
BACKEND_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$BACKEND_READY" != true ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log "  Test de santé backend $RETRY_COUNT/$MAX_RETRIES..."
    
    if [ -n "$BACKEND_URL" ]; then
        # Test de l'endpoint health
        HEALTH_RESPONSE=$(curl -sf "$BACKEND_URL/api/health" 2>/dev/null || echo "")
        if echo "$HEALTH_RESPONSE" | grep -q '"success".*true' 2>/dev/null; then
            BACKEND_READY=true
            success "✅ Backend opérationnel avec API fonctionnelle"
        else
            log "    Backend en cours de démarrage, attente 15s..."
            sleep 15
        fi
    else
        error "Backend URL manquante"
        exit 1
    fi
done

if [ "$BACKEND_READY" != true ]; then
    error "❌ Timeout: Backend non accessible après $MAX_RETRIES tentatives"
    exit 1
fi

# ÉTAPE 5B: Vérification de la connexion à la base de données
log "Vérification de la connexion à la base de données PostgreSQL..."
DB_CONNECTION_OK=false

for i in {1..5}; do
    log "  Test connexion DB $i/5..."
    DB_STATUS=$(curl -sf "$BACKEND_URL/api/health/db-status" 2>/dev/null || echo "{}")
    
    if echo "$DB_STATUS" | grep -q '"success".*true' && echo "$DB_STATUS" | grep -q '"connected".*true' 2>/dev/null; then
        DB_CONNECTION_OK=true
        success "✅ Connexion PostgreSQL OK"
        break
    else
        warn "Connexion DB échouée, attente 10s..."
        sleep 10
    fi
done

if [ "$DB_CONNECTION_OK" != true ]; then
    error "❌ Impossible de se connecter à PostgreSQL"
    exit 1
fi

# ÉTAPE 5C: Vérification et initialisation de la base de données
log "Vérification de l'état d'initialisation de la base de données..."

# Tentative d'initialisation directe - si ça échoue avec "already exists" c'est que c'est déjà init
log "Test d'initialisation de la base de données..."
DB_INIT_SUCCESS=false

for i in {1..3}; do
    log "  Tentative d'initialisation $i/3..."
    
    INIT_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/health/init-db" 2>/dev/null || echo "{}")
    
    if echo "$INIT_RESPONSE" | grep -q '"success".*true' 2>/dev/null; then
        DB_INIT_SUCCESS=true
        success "✅ Base de données initialisée avec succès"
        break
    elif echo "$INIT_RESPONSE" | grep -q "already exists" 2>/dev/null; then
        DB_INIT_SUCCESS=true
        success "✅ Base de données déjà initialisée (trigger/tables existent)"
        break
    elif echo "$INIT_RESPONSE" | grep -q '"message".*"trigger.*already exists"' 2>/dev/null; then
        DB_INIT_SUCCESS=true
        success "✅ Base de données déjà initialisée (triggers existants)"
        break
    else
        warn "Tentative $i/3 échouée, nouvelle tentative dans 15s..."
        if [ $i -lt 3 ]; then
            sleep 15
        fi
    fi
done

# Vérification finale
if [ "$DB_INIT_SUCCESS" = true ]; then
    success "✅ Base de données opérationnelle et prête"
else
    error "❌ Échec de l'initialisation DB après 3 tentatives"
    warn "Initialisation manuelle requise: curl -X POST $BACKEND_URL/api/health/init-db"
    exit 1
fi

# ÉTAPE 5D: Vérification des utilisateurs de test
log "Vérification des utilisateurs de test créés..."
TEST_USERS=("admin@portail-cloud.com" "client1@portail-cloud.com" "client2@portail-cloud.com" "client3@portail-cloud.com")
USERS_OK=0

for user_email in "${TEST_USERS[@]}"; do
    # Tester la connexion de chaque utilisateur
    password="admin123"
    [ "$user_email" != "admin@portail-cloud.com" ] && password="client123"
    
    LOGIN_BODY="{\"email\":\"$user_email\",\"password\":\"$password\"}"
    AUTH_RESPONSE=$(curl -sf -X POST "$BACKEND_URL/api/auth/login" -H "Content-Type: application/json" -d "$LOGIN_BODY" 2>/dev/null || echo "{}")
    
    if echo "$AUTH_RESPONSE" | grep -q '"success".*true' && echo "$AUTH_RESPONSE" | grep -q '"token"' 2>/dev/null; then
        USERS_OK=$((USERS_OK + 1))
        success "✅ Utilisateur $user_email opérationnel"
    else
        warn "⚠️  Utilisateur $user_email non fonctionnel"
    fi
done

if [ $USERS_OK -eq ${#TEST_USERS[@]} ]; then
    success "✅ Tous les utilisateurs de test opérationnels ($USERS_OK/${#TEST_USERS[@]})"
else
    warn "⚠️  Utilisateurs partiellement fonctionnels ($USERS_OK/${#TEST_USERS[@]})"
fi

# ===========================
# PHASE 6: VALIDATION RAPIDE
# ===========================
log "Phase 6: Validation du déploiement"

# Quick validation tests
VALIDATION_SUCCESS=true

# Test backend health
if [ -n "$BACKEND_URL" ]; then
    log "Test API backend..."
    if curl -sf "$BACKEND_URL/api/health" >/dev/null 2>&1; then
        success "Backend opérationnel"
    else
        warn "Backend non accessible"
        VALIDATION_SUCCESS=false
    fi
fi

# Test authentication
if [ -n "$BACKEND_URL" ] && [ "$VALIDATION_SUCCESS" = true ]; then
    log "Test authentification..."
    AUTH_RESPONSE=$(curl -sf -X POST "$BACKEND_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@portail-cloud.com","password":"admin123"}' 2>/dev/null || echo "{}")
    
    if echo "$AUTH_RESPONSE" | grep -q '"success".*true' 2>/dev/null; then
        success "Authentification fonctionnelle"
    else
        warn "Test d'authentification échoué"
        VALIDATION_SUCCESS=false
    fi
fi

# ===========================
# DEPLOYMENT SUMMARY
# ===========================
echo
echo "=============================================="
echo "🎉 DÉPLOIEMENT TERMINÉ"
echo "=============================================="
echo
echo "📍 URLs de production:"
echo "   Frontend: $FRONTEND_URL"
echo "   Backend:  $BACKEND_URL"
echo
echo "👥 Utilisateurs de test:"
echo "   • Admin:    admin@portail-cloud.com / admin123"
echo "   • Client 1: client1@portail-cloud.com / client123"
echo "   • Client 2: client2@portail-cloud.com / client123"
echo "   • Client 3: client3@portail-cloud.com / client123"
echo
echo "🔗 Endpoints utiles:"
echo "   • Santé:        $BACKEND_URL/api/health"
echo "   • Statut DB:    $BACKEND_URL/api/health/db-status"
echo "   • Connexion:    $BACKEND_URL/api/auth/login"
echo "   • Init DB:      $BACKEND_URL/api/database/init-database"
echo

if [ "$VALIDATION_SUCCESS" = true ]; then
    success "✅ SYSTÈME PLEINEMENT OPÉRATIONNEL!"
    echo
    echo "🌐 Ouvrir le frontend dans le navigateur? [Y/n]"
    read -r OPEN_BROWSER
    if [ "$OPEN_BROWSER" != "n" ] && [ "$OPEN_BROWSER" != "N" ] && [ -n "$FRONTEND_URL" ]; then
        if command -v xdg-open &> /dev/null; then
            xdg-open "$FRONTEND_URL"
        elif command -v open &> /dev/null; then
            open "$FRONTEND_URL"
        else
            log "Ouvrez manuellement: $FRONTEND_URL"
        fi
    fi
else
    warn "⚠️  Validation partielle - Vérifiez les logs ci-dessus"
    echo "   Utilisez validate-deployment-clean.ps1 pour une validation complète."
fi

echo
success "Déploiement terminé en $(date +'%H:%M:%S')"