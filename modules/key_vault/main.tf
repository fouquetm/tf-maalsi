# key vault creation
resource "random_string" "kv_name" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.base_name}-${random_string.kv_name.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

resource "azurerm_role_assignment" "kv_secrets_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.owner_object_id
}

resource "azurerm_role_assignment" "kv_keys_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = var.owner_object_id
}

resource "azurerm_role_assignment" "kv_certs_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = var.owner_object_id
}