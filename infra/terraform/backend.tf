terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-bbih"
    storage_account_name = "sttfstatebbih"
    container_name       = "tfstate"
    key                  = "maryam-repo-vm-group4c.tfstate"
  }
}
