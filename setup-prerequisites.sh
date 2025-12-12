#!/bin/bash

# =============================================================
# SETUP PREREQUISITES - SCRIPT DE CONFIGURATION AUTOMATIQUE
# =============================================================

set -e
export DEBIAN_FRONTEND=noninteractive

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log() { echo -e "${CYAN}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1"; exit 1; }

# Generic wait function (shared with main script)
wait_for_condition() {
    local description="$1"
    local test_command="$2"
    local max_attempts="${3:-20}"
    local sleep_time="${4:-15}"
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if eval "$test_command" &>/dev/null; then
            success "✅ $description - OK"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log "  Attente $description $attempt/$max_attempts (${sleep_time}s)..."
            sleep "$sleep_time"
        fi
        
        ((attempt++))
    done
    
    return 1  # Failed
}

# =============================================================
# SYSTEM DETECTION
# =============================================================
detect_system() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
        echo "windows"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

SYSTEM=$(detect_system)
log "🔍 Système détecté: $SYSTEM"

# =============================================================
# GENERIC CHECK AND INSTALL FUNCTION
# =============================================================
check_and_install() {
    local tool_name="$1"
    local check_command="$2"
    local install_function="$3"
    
    if eval "$check_command" &>/dev/null; then
        local version=$(eval "$check_command" 2>/dev/null | head -1 || echo "version inconnue")
        success "$tool_name déjà installé ($version)"
        return 0
    else
        log "Installation de $tool_name..."
        eval "$install_function"
        
        if eval "$check_command" &>/dev/null; then
            local version=$(eval "$check_command" 2>/dev/null | head -1 || echo "installé")
            success "$tool_name installé avec succès ($version)"
        else
            error "Échec de l'installation de $tool_name"
        fi
    fi
}

# =============================================================
# INSTALLATION FUNCTIONS
# =============================================================

install_jq() {
    case $SYSTEM in
        "windows")
            if command -v curl &>/dev/null; then
                curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe -o /tmp/jq.exe 2>/dev/null
                chmod +x /tmp/jq.exe
                export PATH="/tmp:$PATH"
                ln -sf /tmp/jq.exe /tmp/jq 2>/dev/null || true
            fi
            ;;
        "linux")
            if command -v apt-get &>/dev/null; then
                sudo apt-get update -qq && sudo apt-get install -y jq
            elif command -v yum &>/dev/null; then
                sudo yum install -y jq
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y jq
            fi
            ;;
        "macos")
            if command -v brew &>/dev/null; then
                brew install jq
            else
                curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 -o /tmp/jq
                chmod +x /tmp/jq
                export PATH="/tmp:$PATH"
            fi
            ;;
    esac
}

install_terraform() {
    local terraform_version="1.5.7"
    local base_url="https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}"
    
    case $SYSTEM in
        "windows")
            local url="${base_url}_windows_amd64.zip"
            ;;
        "linux")
            local url="${base_url}_linux_amd64.zip"
            ;;
        "macos")
            if command -v brew &>/dev/null; then
                brew tap hashicorp/tap && brew install hashicorp/tap/terraform
                return
            fi
            local url="${base_url}_darwin_amd64.zip"
            ;;
    esac
    
    mkdir -p /tmp/terraform
    cd /tmp/terraform
    curl -L "$url" -o terraform.zip
    
    if command -v unzip &>/dev/null; then
        unzip -o terraform.zip
    elif [[ $SYSTEM == "windows" ]]; then
        powershell.exe -Command "Expand-Archive -Path 'terraform.zip' -DestinationPath '.' -Force" 2>/dev/null
    fi
    
    chmod +x terraform* 2>/dev/null
    [[ $SYSTEM == "windows" ]] && mv terraform terraform.exe 2>/dev/null || true
    export PATH="/tmp/terraform:$PATH"
    cd - >/dev/null
}

install_azure_cli() {
    case $SYSTEM in
        "windows")
            if command -v winget.exe &>/dev/null; then
                winget.exe install Microsoft.AzureCLI --silent --accept-source-agreements --accept-package-agreements 2>/dev/null || {
                    powershell.exe -Command "Invoke-WebRequest -Uri 'https://aka.ms/installazurecliwindows' -OutFile '\$env:TEMP\\azure-cli.msi'; Start-Process msiexec.exe -Wait -ArgumentList '/i', '\$env:TEMP\\azure-cli.msi', '/quiet'" 2>/dev/null
                }
            else
                powershell.exe -Command "Invoke-WebRequest -Uri 'https://aka.ms/installazurecliwindows' -OutFile '\$env:TEMP\\azure-cli.msi'; Start-Process msiexec.exe -Wait -ArgumentList '/i', '\$env:TEMP\\azure-cli.msi', '/quiet'" 2>/dev/null
            fi
            export PATH="/c/Program Files/Microsoft SDKs/Azure/CLI2/wbin:/c/Program Files (x86)/Microsoft SDKs/Azure/CLI2/wbin:$PATH"
            ;;
        "linux")
            if command -v apt-get &>/dev/null; then
                curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            elif command -v yum &>/dev/null; then
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                sudo yum install -y azure-cli
            elif command -v dnf &>/dev/null; then
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                sudo dnf install -y azure-cli
            fi
            ;;
        "macos")
            if command -v brew &>/dev/null; then
                brew install azure-cli
            else
                curl -L https://aka.ms/InstallAzureCli | bash
            fi
            ;;
    esac
}

# =============================================================
# DOCKER MANAGEMENT
# =============================================================
ensure_docker() {
    if ! command -v docker &>/dev/null; then
        error "Docker non installé. Installez Docker Desktop depuis: https://www.docker.com/products/docker-desktop"
    fi
    
    # Check if Docker daemon is running
    if docker ps &>/dev/null; then
        success "Docker daemon opérationnel"
        return 0
    fi
    
    log "Démarrage de Docker..."
    case $SYSTEM in
        "windows")
            # Try to start Docker Desktop
            local docker_paths=(
                "/c/Program Files/Docker/Docker/Docker Desktop.exe"
                "/c/Users/$USER/AppData/Local/Programs/Docker/Docker/Docker Desktop.exe"
            )
            
            for docker_path in "${docker_paths[@]}"; do
                if [[ -f "$docker_path" ]]; then
                    log "Lancement de Docker Desktop..."
                    nohup "$docker_path" >/dev/null 2>&1 &
                    break
                fi
            done
            ;;
        "linux")
            sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null
            ;;
        "macos")
            open -a "Docker Desktop" 2>/dev/null || open "/Applications/Docker.app" 2>/dev/null
            ;;
    esac
    
    # Wait for Docker using generic function (optimized)
    if ! wait_for_condition "Docker daemon opérationnel" "docker ps" 24 5; then
        error "Docker daemon inaccessible après 2 minutes. Démarrez Docker manuellement."
    fi
}

# =============================================================
# AZURE SETUP
# =============================================================
setup_azure() {
    log "Configuration Azure..."
    
    # Check Azure login
    if ! az account show &>/dev/null; then
        log "Connexion Azure requise..."
        az login
    fi
    
    # Get account info
    local subscription_id=$(az account show --query "id" -o tsv 2>/dev/null)
    local user_name=$(az account show --query "user.name" -o tsv 2>/dev/null)
    
    success "Connecté à Azure: $user_name"
    success "Subscription: $subscription_id"
    
    # Register required Azure providers (optimized - batch check)
    log "Vérification des providers Azure..."
    local providers=("Microsoft.App" "Microsoft.ContainerRegistry" "Microsoft.ContainerService" "Microsoft.OperationalInsights" "Microsoft.DBforPostgreSQL")
    
    # Get all provider statuses in one call (optimized)
    local provider_states=$(az provider list --query "[?namespace=='Microsoft.App' || namespace=='Microsoft.ContainerRegistry' || namespace=='Microsoft.ContainerService' || namespace=='Microsoft.OperationalInsights' || namespace=='Microsoft.DBforPostgreSQL'].{namespace:namespace,state:registrationState}" -o tsv 2>/dev/null)
    
    for provider in "${providers[@]}"; do
        if echo "$provider_states" | grep -q "$provider.*Registered" 2>/dev/null; then
            success "Provider $provider déjà enregistré"
        else
            log "Enregistrement du provider $provider..."
            az provider register --namespace "$provider" --no-wait 2>/dev/null || true
        fi
    done
    
    success "Providers Azure configurés"
    
    # Export variables for main script
    echo "export AZURE_SUBSCRIPTION_ID='$subscription_id'"
    echo "export AZURE_USER_NAME='$user_name'"
    echo "export UNIQUE_ID='$(echo "$user_name" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-8)'"
}

# =============================================================
# MAIN EXECUTION
# =============================================================
main() {
    log "🚀 CONFIGURATION AUTOMATIQUE DES PRÉREQUIS"
    
    # Install dependencies
    check_and_install "jq" "jq --version" "install_jq"
    check_and_install "Terraform" "terraform version" "install_terraform"
    check_and_install "Azure CLI" "az version" "install_azure_cli"
    
    # Ensure Docker is running
    ensure_docker
    
    # Setup Azure and export variables
    setup_azure
    
    success "✅ Tous les prérequis configurés avec succès!"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi