# rédiger le code d'infra principal
locals {
  base_name = "${var.project}-${var.environment}"
  restricted_base_name = lower(replace(local.base_name, "-", ""))
  restricted_unique_base_name = "${local.restricted_base_name}${random_string.unique_suffix.result}"
}

resource "random_string" "unique_suffix" {
  length = 6
  special = false
  upper = false
  numeric = true
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.base_name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_storage_account" "main" {
  name                     = "st${local.restricted_unique_base_name}"
  location                 = data.azurerm_resource_group.main.location
  resource_group_name      = data.azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}