terraform {
  backend "azurerm" {
    resource_group_name  = "rg-todolist-prod"
    storage_account_name = "yourstorageaccount"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}