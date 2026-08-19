variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo usado para nombrar los recursos"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group donde se crea el Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID de Azure AD"
  type        = string
}

variable "ssh_public_key" {
  description = "Valor de la SSH public key a guardar como secreto"
  type        = string
  sensitive   = true
}

variable "pipeline_principal_id" {
  description = "Object ID del Service Principal del pipeline. Vacío = no se crea el role assignment \"Key Vault Secrets Officer\"."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags aplicados a los recursos"
  type        = map(string)
  default     = {}
}
