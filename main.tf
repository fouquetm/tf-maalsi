locals {
  base_name = "${var.project}-${var.environment}"
}

# key vault creation
resource "random_string" "kv_name" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_key_vault" "main" {
  name                        = "kv-${local.base_name}-${random_string.kv_name.result}"
  location                    = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

resource "azurerm_role_assignment" "kv_secrets_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_keys_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_certs_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# mssql server creation
resource "random_password" "mssql_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_string" "mssql_suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_mssql_server" "main" {
  name                         = "sqlsrv-${local.base_name}-${random_string.mssql_suffix.result}"
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = data.azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.mssql_login
  administrator_login_password = random_password.mssql_password.result
}

resource "azurerm_key_vault_secret" "mssql-login" {
  name         = "mssql-login"
  value        = var.mssql_login
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_admin
  ]
}

resource "azurerm_key_vault_secret" "mssql-password" {
  name         = "mssql-password"
  value        = random_password.mssql_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_admin
  ]
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "rabbitmqdemo" {
  name         = "RabbitMqDemo"
  server_id    = azurerm_mssql_server.main.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"
  enclave_type = "VBS"
}

resource "azurerm_key_vault_secret" "rabbitmqdemo-sql-connection-string" {
  name         = "rabbitmqdemo-sql-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.rabbitmqdemo.name};Persist Security Info=False;User ID=${var.mssql_login};Password=${random_password.mssql_password.result};Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.main.id
}

# rabbitmq creation
resource "random_password" "rabbitmq_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "rabbitmq_login" {
  name         = "rabbitmq-login"
  value        = var.rabbitmq_login
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_admin
  ]
}

resource "azurerm_key_vault_secret" "rabbitmq-password" {
  name         = "rabbitmq-password"
  value        = random_password.rabbitmq_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_admin
  ]
}

resource "azurerm_container_group" "rabbitmq" {
  name                = "ci-${local.base_name}-rbmq"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = "ci-${local.base_name}-rbmq"
  os_type             = "Linux"

  image_registry_credential {
    server   = data.azurerm_container_registry.main.login_server
    username = data.azurerm_container_registry.main.admin_username
    password = data.azurerm_container_registry.main.admin_password
  }

  exposed_port = [
    {
      port     = 5672
      protocol = "TCP"
    },
    {
      port     = 15672
      protocol = "TCP"
    }
  ]

  container {
    name   = "rabbitmq"
    image  = "acrmaalsimfolabs.azurecr.io/rabbitmq:3-management"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 5672
      protocol = "TCP"
    }

    ports {
      port     = 15672
      protocol = "TCP"
    }

    secure_environment_variables = {
      "RABBITMQ_DEFAULT_USER" = var.rabbitmq_login
      "RABBITMQ_DEFAULT_PASS" = random_password.rabbitmq_password.result
    }
  }
}

# api web app creation
resource "azurerm_service_plan" "main" {
  name                = "asp-${local.base_name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "random_string" "api_suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_linux_web_app" "api" {
  name                = "api-${local.base_name}-${random_string.api_suffix.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name        = "matthieuf/pubsub-api:1.3"
      docker_registry_url      = "https://${data.azurerm_container_registry.main.login_server}"
      docker_registry_username = data.azurerm_container_registry.main.admin_username
      docker_registry_password = data.azurerm_container_registry.main.admin_password
    }
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = azurerm_key_vault_secret.rabbitmqdemo-sql-connection-string.value
  }

  app_settings = {
    "RabbitMQ__Hostname" = azurerm_container_group.rabbitmq.fqdn
    "RabbitMQ__Username" = var.rabbitmq_login
    "RabbitMQ__Password" = random_password.rabbitmq_password.result
  }
}

# console creation
resource "azurerm_container_group" "console" {
  name                = "ci-${local.base_name}-console"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  ip_address_type     = "None"
  os_type             = "Linux"

  image_registry_credential {
    server   = data.azurerm_container_registry.main.login_server
    username = data.azurerm_container_registry.main.admin_username
    password = data.azurerm_container_registry.main.admin_password
  }

  container {
    name   = "console"
    image  = "acrmaalsimfolabs.azurecr.io/matthieuf/pubsub-console:1.0"
    cpu    = "0.5"
    memory = "1.5"

    environment_variables = {
      "RabbitMQ__Hostname" = azurerm_container_group.rabbitmq.fqdn
    }

    secure_environment_variables = {
      "RabbitMQ__Username" = var.rabbitmq_login
      "RabbitMQ__Password" = random_password.rabbitmq_password.result
    }
  }
}