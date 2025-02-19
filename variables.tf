variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "mssql_login" {
  description = "SQL Server admin login"
  type        = string
  sensitive   = true
}

variable "rabbitmq_login" {
  description = "RabbitMQ admin login"
  type        = string
  sensitive   = true
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
}
