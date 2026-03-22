terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.60.0"

    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "db32f9ec-acc7-4507-90c8-6c0798ff4278"

}



