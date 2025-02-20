variable "base_name" {
  description = "The base name for the resources"
  type        = string
}

variable "mssql_login" {
  description = "The login for the MSSQL server"
  type        = string
  sensitive   = true
}

variable "key_vault_id" {
  description = "The ID of the key vault"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location for the resources"
  type        = string
}

variable "database_name" {
  description = "The name of the database"
  type        = string
}

variable "mssql_server_name" {
  description = "The name of the MSSQL server"
  type        = string
  default     = null
}
