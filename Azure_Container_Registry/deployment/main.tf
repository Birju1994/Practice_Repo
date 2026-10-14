module "container_registry" {
  source = "../Modules/azurerm_acr"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  acr_name                      = var.acr_name
  sku_name                      = var.sku_name
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  retention_policy_in_days      = var.retention_policy_in_days
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  tags                          = var.tags
  identity_type                 = var.identity_type
  georeplications_config        = var.georeplications_config

  network_rule_set = var.network_rule_set
}

