data "azuread_application" "app" {
   client_id = var.application_id
}

resource "time_offset" "secret_expiry" {
  offset_hours = var.secret_validity_hours
}
resource "azuread_application_password" "app" {
  application_id                    = azuread_application.app.client_id
  display_name = var.secret_display_name
  end_date = time_offset.secret_expiry.rfc3339
}

resource "azurerm_key_vault_secret" "secret" {
  name = var.key_vault_secret_name
  value = azuread_application_password.app.value
  key_vault_id = var.key_vault_id 
  expiration_date = time_offset.secret_expiry.rfc3339

}



