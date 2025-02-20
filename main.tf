locals {
  base_name = "${var.project}-${var.environment}"
}

# key vault creation
module "key_vault" {
  source              = "./modules/key_vault"
  base_name           = local.base_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  owner_object_id     = data.azurerm_client_config.current.object_id
}

# mssql server creation
module "mssql_database" {
  source              = "./modules/mssql_database"
  base_name           = local.base_name
  mssql_login         = var.mssql_login
  key_vault_id        = module.key_vault.key_vault_id
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  database_name       = "RabbitMqDemo"
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
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [
    module.key_vault
  ]
}

resource "azurerm_key_vault_secret" "rabbitmq-password" {
  name         = "rabbitmq-password"
  value        = random_password.rabbitmq_password.result
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [
    module.key_vault
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
    value = module.mssql_database.database-sql-connection-string
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
