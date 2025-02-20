# définir les providers utilisés
# doc azurerm provider : https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.19.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = null
    storage_account_name = null
    container_name       = "tfstates"
    key                  = "pub-sub.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
}
