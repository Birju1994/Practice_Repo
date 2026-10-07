variable "acr_name" {
  description = "The name of the Azure Container Registry. Must be globally unique, alphanumeric only, 5-50 characters."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Container Registry."
  type        = string
}

variable "location" {
  description = "The Azure region where the Container Registry should be created."
  type        = string
}

variable "sku" {
  description = "The SKU name of the Container Registry. Options are Basic, Standard, and Premium."
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Specifies whether the admin user is enabled on the Container Registry."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
