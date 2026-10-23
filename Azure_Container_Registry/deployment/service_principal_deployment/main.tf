module "service_principal" {
    source = "../../Modules/azure_spn"

    application_id = var.application_id
    secret_validity_hours = var.secret_validity_hours
    secret_display_name = var.secret_display_name
    key_vault_secret_name = var.keyvault_secret_name
    key_vault_id = var.secret_id
    
}
