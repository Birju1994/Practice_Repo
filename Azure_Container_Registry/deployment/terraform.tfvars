rg_name                       = "test2-rg"
rg_location                   = "East US"
acr_name                      = "acr25github02dev"
sku_name                      = "Premium"
admin_enabled                 = false
public_network_access_enabled = true
retention_policy_in_days      = 7
zone_redundancy_enabled = true
tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
}
identity_type = "SystemAssigned"

georeplications_config = {
  georeplica1 = {
    location                        = "Central India"
    global_endpoint_routing_enabled = false
    zone_redundancy_enabled         = false
    tags = {
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}
network_rule_set = {
  default_action = "Allow"

  ip_rules = [
    {
      action   = "Allow"
      ip_range = "172.172.182.68/32"
    }
  ]
}
