# =====================================================
# PORTAIL CLOUD CONTAINER - AZURE TERRAFORM CONFIG
# Phase 1: Infrastructure de base (Registry + PostgreSQL)
# =====================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data sources
data "azurerm_client_config" "current" {}

# Variables
variable "unique_id" {
  description = "Identifiant unique pour les noms des ressources"
  type        = string
  validation {
    condition     = length(var.unique_id) <= 8 && can(regex("^[a-z0-9]+$", var.unique_id))
    error_message = "L'unique_id doit être alphanumérique en minuscules et max 8 caractères."
  }
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "francecentral"
}



# Génération de mots de passe sécurisés
resource "random_password" "postgres_password" {
  length  = 16
  special = true
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-container-manager-${var.unique_id}"
  location = var.location

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Container Registry pour stocker les images Docker
resource "azurerm_container_registry" "main" {
  name                = "acr${var.unique_id}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "logs-${var.unique_id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  name                = "env-${var.unique_id}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# PostgreSQL Flexible Server pour la base de données
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "postgres-${var.unique_id}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  version             = "15"

  administrator_login    = "postgres"
  administrator_password = random_password.postgres_password.result

  zone                        = "1"
  storage_mb                  = 32768
  sku_name                    = "B_Standard_B1ms"
  backup_retention_days       = 7
  geo_redundant_backup_enabled = false

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Base de données PostgreSQL
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "portail_cloud_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "utf8"
  collation = "en_US.utf8"
}

# Règle firewall pour permettre l'accès depuis Azure
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Règle firewall pour permettre l'accès externe (pour les tests)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# Outputs pour récupérer les informations importantes
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "container_registry_admin_username" {
  value = azurerm_container_registry.main.admin_username
}

output "container_registry_admin_password" {
  value = azurerm_container_registry.main.admin_password
  sensitive = true
}

output "container_app_environment_id" {
  value = azurerm_container_app_environment.main.id
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_password" {
  value = random_password.postgres_password.result
  sensitive = true
}

output "jwt_secret" {
  value = random_password.jwt_secret.result
  sensitive = true
}

output "postgres_database_name" {
  value = azurerm_postgresql_flexible_server_database.main.name
}

output "database_url" {
  value = "postgresql://postgres:${random_password.postgres_password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  sensitive = true
}

# Outputs pour les Container Apps
output "backend_url" {
  description = "URL du backend Container App"
  value = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "frontend_url" {
  description = "URL du frontend Container App"  
  value = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "backend_fqdn" {
  description = "FQDN du backend Container App"
  value = azurerm_container_app.backend.ingress[0].fqdn
}

output "frontend_fqdn" {
  description = "FQDN du frontend Container App"
  value = azurerm_container_app.frontend.ingress[0].fqdn
}