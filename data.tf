data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = "rg-maalsi-24-2-mfolabs"
}

data "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.main.name
}
