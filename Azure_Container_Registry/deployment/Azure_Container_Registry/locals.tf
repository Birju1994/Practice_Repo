locals {
  is_premium = var.sku_name == "Premium"

  # Premium-only features
  effective_zone_redundancy = local.is_premium ? var.zone_redundancy_enabled : null

  effective_retention_days = local.is_premium ? var.retention_policy_in_days : null

  effective_georeplications = local.is_premium ? var.georeplications_config : {}

  effective_network_rules = local.is_premium ? var.network_rule_set : null
}

locals {
  effective_network_rules = (
    var.public_network_access == "Selected networks" &&
    length(var.allowed_ip_ranges) > 0
  ) ? {
    default_action = "Deny"
    ip_rules = [
      for ip in var.allowed_ip_ranges : {
        action   = "Allow"
        ip_range = ip
      }
    ]
  } : null
}

