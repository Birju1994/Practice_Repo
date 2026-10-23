terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.8.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "8fecf497-861e-40f9-922a-09f095a29168"
}