locals {
  mssql_server_fqdn     = var.mssql_server_name == null ? azurerm_mssql_server.main[0].fully_qualified_domain_name : data.azurerm_mssql_server.main[0].fully_qualified_domain_name
  mssql_server_id       = var.mssql_server_name == null ? azurerm_mssql_server.main[0].id : data.azurerm_mssql_server.main[0].id
  mssql_server_login    = var.mssql_server_name == null ? azurerm_key_vault_secret.mssql-login[0].value : data.azurerm_key_vault_secret.mssql-login[0].value
  mssql_server_password = var.mssql_server_name == null ? azurerm_key_vault_secret.mssql-password[0].value : data.azurerm_key_vault_secret.mssql-password[0].value
  mssql_server_name     = var.mssql_server_name == null ? "sqlsrv-${var.base_name}-${random_string.mssql_suffix[0].result}" : var.mssql_server_name
}

########################
# MSSQL Server exists
########################
data "azurerm_mssql_server" "main" {
  count               = var.mssql_server_name == null ? 0 : 1
  name                = var.mssql_server_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "mssql-login" {
  count        = var.mssql_server_name == null ? 0 : 1
  name         = "mssql-login"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "mssql-password" {
  count        = var.mssql_server_name == null ? 0 : 1
  name         = "mssql-password"
  key_vault_id = var.key_vault_id
}

########################
# MSSQL Server must be created
########################
resource "random_password" "mssql_password" {
  count            = var.mssql_server_name == null ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_string" "mssql_suffix" {
  count   = var.mssql_server_name == null ? 1 : 0
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_mssql_server" "main" {
  count                        = var.mssql_server_name == null ? 1 : 0
  name                         = local.mssql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.mssql_login
  administrator_login_password = random_password.mssql_password[0].result
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count            = var.mssql_server_name == null ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = local.mssql_server_id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_key_vault_secret" "mssql-login" {
  count        = var.mssql_server_name == null ? 1 : 0
  name         = "mssql-login"
  value        = var.mssql_login
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "mssql-password" {
  count        = var.mssql_server_name == null ? 1 : 0
  name         = "mssql-password"
  value        = random_password.mssql_password[0].result
  key_vault_id = var.key_vault_id
}

########################
# Database creation
########################
resource "azurerm_mssql_database" "main" {
  name         = var.database_name
  server_id    = local.mssql_server_id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"
  enclave_type = "VBS"
}

resource "azurerm_key_vault_secret" "database-sql-connection-string" {
  name         = "${var.database_name}-sql-connection-string"
  value        = "Server=tcp:${local.mssql_server_fqdn},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${local.mssql_server_login};Password=${local.mssql_server_password};Connection Timeout=30;"
  key_vault_id = var.key_vault_id
}
