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
# GENERIC WAIT FUNCTION FOR CONDITIONS
# =============================================================
wait_for_condition() {
    local description="$1"
    local test_command="$2"
    local max_attempts="${3:-20}"
    local sleep_time="${4:-15}"
    local attempt=1
    
    log "Attente: $description (max $max_attempts tentatives)..."
    
    while [[ $attempt -le $max_attempts ]]; do
        log "  Tentative $attempt/$max_attempts..."
        
        if eval "$test_command" &>/dev/null; then
            success "✅ $description - OK"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log "    Attente ${sleep_time}s avant nouvelle tentative..."
            sleep "$sleep_time"
        fi
        
        ((attempt++))
    done
    
    error "❌ Timeout: $description après $max_attempts tentatives"
}

# =============================================================
# PREREQUISITES SETUP (DELEGATED TO EXTERNAL SCRIPT)
# =============================================================
setup_prerequisites() {
    log "🔧 Configuration des prérequis..."
    
    # Check if setup script exists
    if [[ ! -f "./setup-prerequisites.sh" ]]; then
        error "Script setup-prerequisites.sh non trouvé dans le répertoire courant"
    fi
    
    # Make it executable and run it
    chmod +x ./setup-prerequisites.sh
    
    # Run setup script with visible logs AND capture output
    ./setup-prerequisites.sh 2>&1 | tee /tmp/setup-output.log
    
    # Extract Azure variables from captured output
    AZURE_SUBSCRIPTION_ID=$(grep "export AZURE_SUBSCRIPTION_ID" /tmp/setup-output.log | cut -d"'" -f2 2>/dev/null)
    AZURE_USER_NAME=$(grep "export AZURE_USER_NAME" /tmp/setup-output.log | cut -d"'" -f2 2>/dev/null)
    UNIQUE_ID=$(grep "export UNIQUE_ID" /tmp/setup-output.log | cut -d"'" -f2 2>/dev/null)
    
    # Validate variables
    if [[ -z "$AZURE_SUBSCRIPTION_ID" ]] || [[ -z "$UNIQUE_ID" ]]; then
        # Fallback: get Azure info directly
        AZURE_SUBSCRIPTION_ID=$(az account show --query "id" -o tsv 2>/dev/null)
        AZURE_USER_NAME=$(az account show --query "user.name" -o tsv 2>/dev/null)
        UNIQUE_ID=$(echo "$AZURE_USER_NAME" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-8)
    fi
    
    # Ensure Terraform is in PATH
    export PATH="/tmp/terraform:$PATH"
    
    success "Variables Azure configurées"




    success "✅ Prérequis configurés avec succès"
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

# Configuration des prérequis (script externe)
setup_prerequisites

# ===========================
# PHASE 0: CONFIGURATION INITIALE
# ===========================
log "Phase 0: Configuration initiale"

# Utiliser les variables du script de setup
USER_NAME="$AZURE_USER_NAME"
SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID"
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
    
    # Wait smartly for cleanup to start (optimized)
    log "Attente intelligente du nettoyage..."
    wait_for_condition "Nettoyage des ressources" \
        "! az group show -n '$RG_NAME' >/dev/null 2>&1 || [ \$(az resource list -g '$RG_NAME' --query 'length(@)' -o tsv 2>/dev/null || echo 10) -lt 5 ]" \
        12 5 || log "Nettoyage en cours, continuons..."
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
    
    # Vérifier l'état actuel de Terraform (sans demander les variables)
    TERRAFORM_STATE=$(terraform state list 2>/dev/null || echo "")
    
    if [ "$BACKEND_EXISTS" != "null" ] && ! echo "$TERRAFORM_STATE" | grep -q "azurerm_container_app.backend"; then
        warn "Import backend existant dans l'état Terraform"
        BACKEND_ID=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "id" -o tsv 2>/dev/null)
        if [ -n "$BACKEND_ID" ]; then
            terraform import -var="unique_id=$UNIQUE_ID" "azurerm_container_app.backend" "$BACKEND_ID" 2>/dev/null || true
        fi
    fi
    
    if [ "$FRONTEND_EXISTS" != "null" ] && ! echo "$TERRAFORM_STATE" | grep -q "azurerm_container_app.frontend"; then
        warn "Import frontend existant dans l'état Terraform"
        FRONTEND_ID=$(az containerapp show --name "frontend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "id" -o tsv 2>/dev/null)
        if [ -n "$FRONTEND_ID" ]; then
            terraform import -var="unique_id=$UNIQUE_ID" "azurerm_container_app.frontend" "$FRONTEND_ID" 2>/dev/null || true
        fi
    fi
fi

# Première étape: déployer seulement l'infrastructure de base (sans Container Apps)
log "Déploiement infrastructure de base (Registry + Database)..."
terraform plan -var="unique_id=$UNIQUE_ID" -target="azurerm_resource_group.main" -target="azurerm_container_registry.main" -target="azurerm_log_analytics_workspace.main" -target="azurerm_postgresql_flexible_server.main" -target="azurerm_postgresql_flexible_server_database.main" -target="azurerm_postgresql_flexible_server_firewall_rule.allow_azure" -target="random_password.postgres_password" -target="random_password.jwt_secret" -out=tfplan-infra
terraform apply -auto-approve tfplan-infra

# Get outputs pour ACR
log "Récupération des informations ACR..."
ACR_SERVER=$(terraform output -raw container_registry_login_server 2>/dev/null)
ACR_NAME=$(terraform output -raw acr_name 2>/dev/null)
DB_URL=$(terraform output -raw database_url 2>/dev/null)

cd ../..

if [ -z "$ACR_SERVER" ] || [ -z "$ACR_NAME" ]; then
    error "Impossible de récupérer les informations ACR depuis Terraform"
fi

success "Infrastructure de base créée: $ACR_SERVER"

# ===========================
# PHASE 3: BACKEND BUILD & DEPLOY (OPTIMISÉ)
# ===========================
if [ "$SKIP_BUILD" != true ]; then
    log "Phase 3: Construction Backend seulement"
    
    # Login to ACR
    log "Connexion à Azure Container Registry..."
    az acr login --name "$ACR_NAME"
    
    # Build et push Backend uniquement
    log "  📦 Construction Backend..."
    docker build -t "$ACR_SERVER/dashboard-backend:latest" ./dashboard-backend
    log "  📤 Push Backend vers ACR..."
    docker push "$ACR_SERVER/dashboard-backend:latest"
    success "✅ Backend construit et poussé"
    
else
    warn "Construction Docker ignorée (--skip-build)"
fi

# ===========================
# PHASE 4: DÉPLOIEMENT BACKEND CONTAINER APP
# ===========================
log "Phase 4: Déploiement Backend Container App"

cd terraform/azure

log "Déploiement du Backend Container App..."
terraform plan -var="unique_id=$UNIQUE_ID" -target="azurerm_container_app_environment.main" -target="azurerm_container_app.backend" -out=tfplan-backend
terraform apply -auto-approve tfplan-backend

# Récupération de l'URL Backend seulement
log "Récupération de l'URL Backend..."
BACKEND_URL=$(terraform output -raw backend_url 2>/dev/null)

cd ../..

if [ -z "$BACKEND_URL" ]; then
    # Fallback Azure CLI
    log "Récupération de l'URL Backend via Azure CLI..."
    BACKEND_FQDN=$(az containerapp show --name "backend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null)
    
    if [ -n "$BACKEND_FQDN" ]; then
        BACKEND_URL="https://$BACKEND_FQDN"
    fi
fi

if [ -z "$BACKEND_URL" ]; then
    error "❌ Impossible de récupérer l'URL du Backend"
fi

success "✅ Backend déployé avec succès"
success "   Backend: $BACKEND_URL"

# ===========================
# PHASE 5: BUILD ET DÉPLOIEMENT FRONTEND AVEC URL CORRECTE
# ===========================
if [ "$SKIP_BUILD" != true ] && [ -n "$BACKEND_URL" ]; then
    log "Phase 5: Build et déploiement Frontend avec l'API URL correcte"
    
    # Attendre que le Backend soit opérationnel (optimisé)
    log "Vérification que le Backend est opérationnel..."
    wait_for_condition "Backend prêt pour frontend" \
        "curl -sf --connect-timeout 3 '$BACKEND_URL/api/health'" \
        5 3 || warn "Backend pas encore prêt, build frontend quand même..."
    
    # Build Frontend avec l'API URL correcte
    log "  📦 Build Frontend avec API URL: $BACKEND_URL/api"
    docker build --build-arg NEXT_PUBLIC_API_URL="$BACKEND_URL/api" -t "$ACR_SERVER/dashboard-frontend:latest" ./dashboard-frontend
    log "  📤 Push Frontend vers ACR..."
    docker push "$ACR_SERVER/dashboard-frontend:latest"
    success "✅ Frontend construit et poussé avec l'API URL correcte"
    
    # Déploiement du Frontend Container App
    log "  🚀 Déploiement Frontend Container App..."
    cd terraform/azure
    terraform plan -var="unique_id=$UNIQUE_ID" -target="azurerm_container_app.frontend" -out=tfplan-frontend
    terraform apply -auto-approve tfplan-frontend
    
    # Récupération URL Frontend
    FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null)
    cd ../..
    
    if [ -z "$FRONTEND_URL" ]; then
        FRONTEND_FQDN=$(az containerapp show --name "frontend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null)
        if [ -n "$FRONTEND_FQDN" ]; then
            FRONTEND_URL="https://$FRONTEND_FQDN"
        fi
    fi
    
    success "✅ Frontend déployé avec succès"
    success "   Frontend: $FRONTEND_URL"
    
    # Déploiement du Frontend Container App
    log "  🚀 Déploiement Frontend Container App..."
    cd terraform/azure
    terraform plan -var="unique_id=$UNIQUE_ID" -target="azurerm_container_app.frontend" -out=tfplan-frontend
    terraform apply -auto-approve tfplan-frontend
    
    # Récupération URL Frontend
    FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null)
    cd ../..
    
    if [ -z "$FRONTEND_URL" ]; then
        FRONTEND_FQDN=$(az containerapp show --name "frontend-$UNIQUE_ID" --resource-group "$RG_NAME" --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null)
        if [ -n "$FRONTEND_FQDN" ]; then
            FRONTEND_URL="https://$FRONTEND_FQDN"
        fi
    fi
    
    success "✅ Frontend déployé avec succès"
    success "   Frontend: $FRONTEND_URL"
    
else
    success "✅ Déploiement terminé (reconstruction Frontend ignorée)"
fi

# ===========================
# PHASE 6: VÉRIFICATIONS FINALES ET RÉSUMÉ
# ===========================
log "Phase 6: Vérifications finales"

# Attendre que les applications soient prêtes (optimisé)
log "Vérification du démarrage des applications..."
wait_for_condition "Applications démarrées" \
    "curl -sf --connect-timeout 3 '$BACKEND_URL/api/health' && curl -sf --connect-timeout 3 '$FRONTEND_URL' >/dev/null" \
    10 3 || log "Applications en cours de démarrage..."

# Test de connectivité final
log "Test de connectivité des applications..."
if [ -n "$BACKEND_URL" ]; then
    if curl -sf --connect-timeout 10 --max-time 15 "$BACKEND_URL/api/health" >/dev/null 2>&1; then
        success "✅ Backend accessible: $BACKEND_URL/api/health"
    else
        warn "⚠ Backend pas encore prêt: $BACKEND_URL/api/health"
    fi
fi

if [ -n "$FRONTEND_URL" ]; then
    if curl -sf --connect-timeout 10 --max-time 15 "$FRONTEND_URL" >/dev/null 2>&1; then
        success "✅ Frontend accessible: $FRONTEND_URL"
    else
        warn "⚠ Frontend pas encore prêt: $FRONTEND_URL"
    fi
fi

# ===========================
# PHASE 7: IMAGES DÉMO (OPTIONNEL)
# ===========================
if [ "$SKIP_BUILD" != true ]; then
    log "Phase 7: Construction des images démo (en parallèle)"
    
    # Build images démo en arrière-plan pour accélérer
    {
        log "  📦 Image Node.js démo..."
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
        
        # Attente DYNAMIQUE que le backend redémarre (optimisée)
        log "Attente du redémarrage backend..."
        
        # Utiliser la fonction générique avec fallback silencieux
        if ! wait_for_condition "Backend redémarrage" \
            "curl -sf --connect-timeout 3 --max-time 8 '$BACKEND_URL/api/health'" \
            15 20 2>/dev/null; then
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
[[ -z "$BACKEND_URL" ]] && error "Backend URL manquante"

# Utilisation de la fonction générique optimisée
wait_for_condition "Backend API opérationnel" \
    "curl -sf '$BACKEND_URL/api/health' | grep -q '\"success\".*true'" \
    20 15

# ÉTAPE 5B: Vérification de la connexion à la base de données
log "Vérification de la connexion à la base de données PostgreSQL..."

# Connexion DB avec fonction générique optimisée
wait_for_condition "Connexion PostgreSQL" \
    "curl -sf '$BACKEND_URL/api/health/db-status' | grep -q '\"success\".*true' && curl -sf '$BACKEND_URL/api/health/db-status' | grep -q '\"connected\".*true'" \
    5 10

# ÉTAPE 5C: Initialisation de la base de données (optimisée)
log "Initialisation de la base de données..."

# Test d'initialisation avec logique simplifiée
INIT_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/health/init-db" 2>/dev/null || echo "{}")

if echo "$INIT_RESPONSE" | grep -q -E '"success".*true|already exists|trigger.*already exists' 2>/dev/null; then
    success "✅ Base de données initialisée et opérationnelle"
else
    # Une seule retry rapide si première tentative échoue (optimisé)
    warn "Première tentative échouée, retry immédiat..."
    sleep 3
    INIT_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/health/init-db" 2>/dev/null || echo "{}")
    
    if echo "$INIT_RESPONSE" | grep -q -E '"success".*true|already exists|trigger.*already exists' 2>/dev/null; then
        success "✅ Base de données initialisée après retry"
    else
        error "❌ Échec initialisation DB. Manuel: curl -X POST $BACKEND_URL/api/health/init-db"
    fi
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