variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}
variable "acr_name" {
  description = "Globally unique Azure Container Registry name"
  type        = string
}

variable "sku_name" {
  description = "SKU for Azure Container Registry"
  type        = string

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable or disable the ACR admin account"
  type        = bool
}

variable "public_network_access_enabled" {
  description = "Enable or disable public network access"
  type        = bool
}

variable "retention_policy_in_days" {
  description = "Retention period in days for eligible untagged manifests"
  type        = number
}

variable "zone_redundancy_enabled" {
  type = bool
}

variable "tags" {
  description = "Tags applied to the Resource Group and ACR"
  type        = map(string)
}

variable "identity_type" {
  description = "Managed identity type for ACR"
  type        = string
}
variable "georeplications_config" {
  description = "Optional ACR geo-replication configuration"

  type = map(object({
    location                        = string
    global_endpoint_routing_enabled = optional(bool, true)
    zone_redundancy_enabled         = optional(bool, false)
    tags                            = optional(map(string), {})
  }))

  default  = null
  nullable = true
}


variable "network_rule_set" {
  description = "ACR network access configuration"

  type = object({
    default_action = optional(string, "Deny")

    ip_rules = list(object({
      action   = optional(string, "Deny")
      ip_range = string
    }))
  })
  default  = null
  nullable = true

}

