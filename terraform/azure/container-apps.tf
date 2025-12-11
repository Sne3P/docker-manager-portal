# Container Apps avec configuration production simple
resource "azurerm_container_app" "backend" {
  name                         = "backend-${var.unique_id}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "backend"
      image  = "${azurerm_container_registry.main.login_server}/dashboard-backend:real-azure-msi"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://postgres:${random_password.postgres_password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/portail_cloud_db?sslmode=require"
      }

      env {
        name  = "JWT_SECRET"
        value = random_password.jwt_secret.result
      }

      env {
        name  = "PORT"
        value = "80"
      }
      
      env {
        name  = "FRONTEND_URL"
        value = "https://frontend-${var.unique_id}.${azurerm_container_app_environment.main.default_domain}"
      }

      env {
        name  = "AZURE_RESOURCE_GROUP"
        value = azurerm_resource_group.main.name
      }

      env {
        name  = "AZURE_CONTAINER_ENVIRONMENT"
        value = azurerm_container_app_environment.main.name
      }

      env {
        name  = "AZURE_CONTAINER_REGISTRY"
        value = azurerm_container_registry.main.login_server
      }

      env {
        name  = "AZURE_CONTAINER_REGISTRY_USERNAME"
        value = azurerm_container_registry.main.admin_username
      }

      env {
        name  = "AZURE_ENVIRONMENT"
        value = "true"
      }

      env {
        name  = "AZURE_CONTAINER_REGISTRY_PASSWORD"
        value = azurerm_container_registry.main.admin_password
      }

      env {
        name  = "AZURE_SUBSCRIPTION_ID"
        value = data.azurerm_client_config.current.subscription_id
      }

      env {
        name  = "AZURE_USE_MSI"
        value = "true"
      }
    }

    min_replicas = 1
    max_replicas = 2
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  registry {
    server               = azurerm_container_registry.main.login_server
    username             = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Assignation des permissions au Managed Identity du backend
resource "azurerm_role_assignment" "backend_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_container_app.backend.identity[0].principal_id

  depends_on = [azurerm_container_app.backend]
}

resource "azurerm_container_app" "frontend" {
  name                         = "frontend-${var.unique_id}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.main.login_server}/dashboard-frontend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "PORT"
        value = "80"
      }
    }

    min_replicas = 1
    max_replicas = 2
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  registry {
    server               = azurerm_container_registry.main.login_server
    username             = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Note: Les rôles seront assignés manuellement après le déploiement initial
# resource "azurerm_role_assignment" "backend_contributor" {
#   scope                = azurerm_resource_group.main.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_container_app.backend.identity[0].principal_id
# }

# resource "azurerm_role_assignment" "backend_container_registry_pull" {
#   scope                = azurerm_container_registry.main.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_container_app.backend.identity[0].principal_id
# }

# Outputs moved to main.tf to avoid duplication