# Azure Infrastructure for Container Management Platform
# Production-ready multi-tenant container platform

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Variables for easy deployment from any environment
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "container-platform"
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "admin_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Container Registry for Docker images
resource "azurerm_container_registry" "main" {
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  sku                = "Basic"
  admin_enabled      = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# PostgreSQL Database for production data
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.project_name}-${var.environment}"
  resource_group_name    = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  version               = "13"
  administrator_login    = "psqladmin"
  administrator_password = var.admin_password
  
  storage_mb = 32768
  sku_name   = "B_Standard_B1ms"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Database for the application
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "containerdb"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# App Service Plan for containers
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  os_type            = "Linux"
  sku_name           = "B1"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Backend API App Service
resource "azurerm_linux_web_app" "backend" {
  name                = "app-${var.project_name}-api-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_service_plan.main.location
  service_plan_id    = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image     = "${azurerm_container_registry.main.login_server}/backend"
      docker_image_tag = "latest"
    }
    always_on = true
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.main.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.main.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.main.admin_password
    
    # Application settings
    NODE_ENV     = "production"
    PORT         = "5000"
    JWT_SECRET   = "production-jwt-secret-change-me"
    JWT_EXPIRES_IN = "24h"
    
    # Database connection
    DATABASE_URL = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:${var.admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Frontend App Service
resource "azurerm_linux_web_app" "frontend" {
  name                = "app-${var.project_name}-web-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_service_plan.main.location
  service_plan_id    = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image     = "${azurerm_container_registry.main.login_server}/frontend"
      docker_image_tag = "latest"
    }
    always_on = true
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.main.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.main.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.main.admin_password
    
    # Frontend configuration
    NEXT_PUBLIC_API_URL = "https://${azurerm_linux_web_app.backend.default_hostname}"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Application Gateway for load balancing (production setup)
resource "azurerm_public_ip" "main" {
  name                = "pip-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                = "Standard"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Outputs for CI/CD and documentation
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "container_registry_url" {
  description = "Container registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "backend_url" {
  description = "Backend API URL"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "https://${azurerm_linux_web_app.frontend.default_hostname}"
}

output "database_connection_string" {
  description = "Database connection string"
  value       = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:${var.admin_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}?sslmode=require"
  sensitive   = true
}