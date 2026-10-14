

output "acr_name" {
  description = "Created Azure Container Registry name"
  value       = module.container_registry.acr_name
}

output "acr_login_server" {
  description = "ACR login server endpoint"
  value       = module.container_registry.acr_login_server
}

output "acr_id" {
  description = "Azure Container Registry resource ID"
  value       = module.container_registry.acr_id
}