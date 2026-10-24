module "container_registry" {
  source = "../../Modules/azurerm_acr"

  # Basic ACR configuration
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  acr_name                      = var.acr_name
  sku_name                      = var.sku_name
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled

  # Premium-only settings
  retention_policy_in_days = (
    var.sku_name == "Premium" ? var.retention_policy_in_days : null
  )

  zone_redundancy_enabled = (
    var.sku_name == "Premium" ? var.zone_redundancy_enabled : null
  )

  georeplications_config = (
    var.sku_name == "Premium" ? var.georeplications_config : {}
  )

  network_rule_set = (
    var.sku_name == "Premium" ? var.network_rule_set : null
  )

  # Identity and tags
  identity_type = var.identity_type
  tags          = var.tags
}




module "domain_name_label" {
  depends_on = [module.container_registry]
  source = "../../Modules/azureapi_label"
  acr_id = module.container_registry.acr_id
  domain_name_label_scope    = var.domain_name_label_scope
}
