
variable "ritm" {
  description = "Unique service request ID for each renewal"
  type        = string

  validation {
    condition     = can(regex("^RITM[0-9]+$", var.ritm))
    error_message = "RITM must use a format such as RITM1234567."
  }
}

variable "dso" {
  description = "DSO identifier for audit traceability"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID selected in the issue form"
  type        = string

  validation {
    condition = can(regex(
      "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
      var.subscription_id
    ))
    error_message = "Provide a valid Azure subscription GUID."
  }
}

variable "application_id" {
  description = "Client ID of the existing App Registration"
  type        = string

  validation {
    condition = can(regex(
      "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
      var.application_id
    ))
    error_message = "Application ID must be a valid GUID."
  }
}

variable "secret_validity_hours" {
  type = number
  default = 
}

variable "secret_display_name" {
  type = string
  default = "vm-password"
}

variable "keyvault_name" {
  description = "Name of the existing Azure Key Vault"
  type        = string
}

variable "keyvault_secret_name" {
  description = "Name of the Key Vault secret to write"
  type        = string
  default = vm-password
}
variable "secret_id" {
  type = string
  default = 
}

variable "keyvault_resource_group_name" {
  description = "Resource group containing the existing Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID"
  type        = string
  sensitive   = true
}

 
