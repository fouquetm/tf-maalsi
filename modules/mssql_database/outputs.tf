output "mssql_server_name" {
  value = local.mssql_server_name
}

output "mssql_server_id" {
  value = local.mssql_server_id
}

output "mssql_server_fqdn" {
  value = local.mssql_server_fqdn
}

output "mssql_server_login" {
  value     = local.mssql_server_login
  sensitive = true
}

output "mssql_server_password" {
  value     = local.mssql_server_password
  sensitive = true
}

output "database_id" {
  value = azurerm_mssql_database.main.id
}

output "database-sql-connection-string" {
  value     = azurerm_key_vault_secret.database-sql-connection-string.value
  sensitive = true
}
