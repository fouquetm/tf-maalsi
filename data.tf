data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = "rg-maalsi-24-2-mfolabs"
}
