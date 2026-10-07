

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment."
  type        = string
  default     = "East US"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry."
  type        = string
}

variable "sku" {
  description = "SKU of the Azure Container Registry (Basic, Standard, Premium)."
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Enable admin user for Azure Container Registry."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
