# définir les valeurs de sortie de Terraform
output "azurerm_mssql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "azurerm_ci_rabbitmq_fqdn" {
  description = "Fully qualified domain name of the RabbitMQ server"
  value       = azurerm_container_group.rabbitmq.fqdn
}

output "rabbitmq_webui_url" {
  description = "URL of the RabbitMQ Management Web UI"
  value       = "http://${azurerm_container_group.rabbitmq.fqdn}:15672/"
}

output "api_url" {
  description = "URL of the API"
  value       = "https://${azurerm_linux_web_app.api.default_hostname}/api/Product/productlist"
}
