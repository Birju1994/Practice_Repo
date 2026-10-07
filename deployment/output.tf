output "container_registry_id" {
  description = "The Resource ID of the Azure Container Registry."
  value       = module.container_registry.acr_id
}

output "container_registry_login_server" {
  description = "The Login Server URL of the Azure Container Registry."
  value       = module.container_registry.acr_login_server
}

output "container_registry_admin_username" {
  description = "The Admin Username for the Azure Container Registry."
  value       = module.container_registry.acr_admin_username
}

output "container_registry_admin_password" {
  description = "The Admin Password for the Azure Container Registry."
  value       = module.container_registry.acr_admin_password
  sensitive   = true
}
