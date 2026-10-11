resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.rg_location
}
resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = var.sku_name
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  retention_policy_in_days      = var.sku_name == "Premium" ? var.retention_policy_in_days : null
  zone_redundancy_enabled       = var.sku_name == "Premium" ? var.zone_redundancy_enabled : null
  tags                          = var.tags

  dynamic "georeplications" {
    for_each = var.sku_name == "Premium" ? var.georeplications_config : {}

    content {
      location = georeplications.value.location

      global_endpoint_routing_enabled = lookup(georeplications.value, "global_endpoint_routing_enabled", true)

      zone_redundancy_enabled = lookup(georeplications.value, "zone_redundancy_enabled", false)

      tags = lookup(georeplications.value, "tags", {})  
    }
  }
  dynamic "network_rule_set" {
    for_each = var.sku_name == "Premium" ? [var.network_rule_set] : []

    content {
      default_action = lookup(network_rule_set.value, "default_action", "Deny")

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules

        content {
          action   = lookup(ip_rule.value, "action", "Allow")
          ip_range = ip_rule.value.ip_range
        }
      }
    }
  }


  identity {
    type = var.identity_type
  }
}

