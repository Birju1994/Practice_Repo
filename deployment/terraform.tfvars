resource_group_name = "rg-acr-demo"
location            = "East US"
acr_name            = "myacrregistrydemo123"
sku                 = "Standard"
admin_enabled       = true
tags = {
  Environment = "Dev"
  ManagedBy   = "Terraform"
}
