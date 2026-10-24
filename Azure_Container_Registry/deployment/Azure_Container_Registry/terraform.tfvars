
resource_group_name           = "Axion-State-RG"
acr_name                      = "acr25github03dev"
sku_name                      = "Premium"
admin_enabled                 = false
public_network_access_enabled = true
retention_policy_in_days      = 90
zone_redundancy_enabled       = true

tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
}

identity_type = "SystemAssigned"


georeplications_config = {
  replica1 = {
    location                        = "Central India"
    global_endpoint_routing_enabled = true
    zone_redundancy_enabled         = true

    tags = {
      Environment = "Dev"
      Cost_Centre = "123456"
    }
  }
}



network_rule_set = {
  default_action = "Deny"

  ip_rules = [
    {
      action   = "Allow"
      ip_range = "172.212.77.60"
    }
  ]
}

domain_name_label_scope = "ResourceGroupReuse"

