variable "application_id" {
    description = "application iddetail"
    type = number
}
variable "secret_validity_hours" {
    type = number
}
variable "secret_display_name" {
    type = string
}
variable "key_vault_secret_name" {
    type = string
}
variable "key_vault_id" {
    type = string
}
