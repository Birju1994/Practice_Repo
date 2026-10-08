output "acr_id" {
  description = "The ID of the Azure Container Registry."
  value       = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  description = "The URL that can be used to log into the container registry."
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "The Username associated with the Container Registry Admin account if enabled."
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  description = "The Password associated with the Container Registry Admin account if enabled."
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}
