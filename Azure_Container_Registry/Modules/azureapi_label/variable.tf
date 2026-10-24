variable "acr_id" {
  description = "The ID of the Azure Container Registry"
  type        = string
}
variable "domain_name_label_scope" {
  description = "Domain Name Label reuse scope for ACR"
  type        = string
  default     = "TenantReuse"

  validation {
    condition = contains([
      "Unsecure",
      "TenantReuse",
      "SubscriptionReuse",
      "ResourceGroupReuse",
      "NoReuse"
    ], var.domain_name_label_scope)

    error_message = "Invalid Domain Name Label scope."
  }
}