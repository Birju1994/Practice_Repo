resource_group_name           = "GITHUB-AZURE-TEST-RG"
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


