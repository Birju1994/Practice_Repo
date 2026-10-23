output "renewed_application_id" {
  description = "Client ID of the renewed App Registration"
  value       = data.azuread_application.existing.client_id
}

output "keyvault_secret_name" {
  description = "Name of the Key Vault secret updated"
  value       = azurerm_key_vault_secret.spn_secret.name
}

