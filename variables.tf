# définir les variables
variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "project" {
  description = "The project name"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}