# =====================================================
# OUTPUTS POUR CONTAINER APPS
# =====================================================
# Ces outputs sont conditionnels et disponibles seulement 
# après déploiement des Container Apps correspondants

# Backend Container App Outputs
output "backend_url" {
  description = "URL du backend Container App"
  value = try("https://${azurerm_container_app.backend.ingress[0].fqdn}", "")
  depends_on = [azurerm_container_app.backend]
}

output "frontend_url" {
  description = "URL du frontend Container App"  
  value = try("https://${azurerm_container_app.frontend.ingress[0].fqdn}", "")
  depends_on = [azurerm_container_app.frontend]
}

output "backend_fqdn" {
  description = "FQDN du backend Container App"
  value = try(azurerm_container_app.backend.ingress[0].fqdn, "")
  depends_on = [azurerm_container_app.backend]
}

output "frontend_fqdn" {
  description = "FQDN du frontend Container App"
  value = try(azurerm_container_app.frontend.ingress[0].fqdn, "")
  depends_on = [azurerm_container_app.frontend]
}

# Status outputs pour debugging
output "backend_latest_revision_name" {
  description = "Nom de la dernière révision backend"
  value = try(azurerm_container_app.backend.latest_revision_name, "")
  depends_on = [azurerm_container_app.backend]
}

output "frontend_latest_revision_name" {
  description = "Nom de la dernière révision frontend"
  value = try(azurerm_container_app.frontend.latest_revision_name, "")
  depends_on = [azurerm_container_app.frontend]
}