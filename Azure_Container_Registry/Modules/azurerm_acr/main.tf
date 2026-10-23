resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = data.azurerm_resource_group.rg.location

  sku                           = var.sku_name
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  zone_redundancy_enabled = local.effective_zone_redundancy
  retention_policy_in_days = local.effective_retention_days

  identity {
    type = var.identity_type
  }

  # Geo-replication: Premium only
  dynamic "georeplications" {
    for_each = local.effective_georeplications

    content {
      location                        = georeplications.value.location
      global_endpoint_routing_enabled = georeplications.value.global_endpoint_routing_enabled
      zone_redundancy_enabled         = georeplications.value.zone_redundancy_enabled
      tags                            = georeplications.value.tags
    }
  }

  # Network rules: Premium only
  dynamic "network_rule_set" {
    for_each = local.effective_network_rules == null ? [] : [
      local.effective_network_rules
    ]

    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules

        content {
          action   = ip_rule.value.action
          ip_range = ip_rule.value.ip_range
        }
      }
    }
  }
}
