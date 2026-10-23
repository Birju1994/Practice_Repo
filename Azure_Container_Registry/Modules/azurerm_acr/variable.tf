
variable "resource_group_name" {
  description = "Name of the existing Azure Resource Group"
  type        = string
}

variable "acr_name" {
  description = "Globally unique Azure Container Registry name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "ACR name must contain 5-50 alphanumeric characters."
  }
}

variable "sku_name" {
  description = "SKU tier for Azure Container Registry"
  type        = string

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "SKU must be Standard or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable or disable the ACR admin account"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable or disable public network access"
  type        = bool
  default     = true
}

variable "retention_policy_in_days" {
  description = "Retention period for eligible untagged manifests; Premium only"
  type        = number
  default     = null
  nullable    = true

  validation {
    condition = (
      var.retention_policy_in_days == null ||
      (var.retention_policy_in_days >= 0 &&
      var.retention_policy_in_days <= 365)
    )
    error_message = "Retention policy must be between 0 and 365 days, or null."
  }
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for Premium ACR"
  type        = bool
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags applied to the Azure Container Registry"
  type        = map(string)
  default     = {}
}

variable "identity_type" {
  description = "Managed identity type for ACR"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition = contains(
      ["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"],
      var.identity_type
    )
    error_message = "Use SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
}

variable "georeplications_config" {
  description = "Map of Premium ACR geo-replication configurations"

  type = map(object({
    location                        = string
    global_endpoint_routing_enabled = optional(bool, true)
    zone_redundancy_enabled         = optional(bool, false)
    tags                            = optional(map(string), {})
  }))

  default  = {}
  nullable = false
}

variable "network_rule_set" {
  description = "Optional Premium ACR network access rules"

  type = object({
    default_action = optional(string, "Deny")

    ip_rules = optional(list(object({
      action   = optional(string, "Allow")
      ip_range = string
    })), [])
  })

  default  = null
  nullable = true

  validation {
    condition = (
      var.network_rule_set == null ||
      contains(["Allow", "Deny"], var.network_rule_set.default_action)
    )
    error_message = "Network default_action must be Allow or Deny."
  }
}
