variable "base_name" {
  description = "Base name for all resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "owner_object_id" {
  description = "Azure AD object ID of the owner"
  type        = string
}
