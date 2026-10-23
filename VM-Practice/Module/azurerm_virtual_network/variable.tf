variable "virtual_network" {
  name                = each.value.vnet_name
  location            = each.value.location
  resource_group_name = ech.value.resource_group_name
  address_space       = rach.value.address_space

}