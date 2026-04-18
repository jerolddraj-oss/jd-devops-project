terraform {
  backend "azurerm" {
    resource_group_name  = "jd-tf-rg"
    storage_account_name = "jdtfstate12345"
    container_name       = "tfstate"
    key                  = "vm.tfstate"
  }
}