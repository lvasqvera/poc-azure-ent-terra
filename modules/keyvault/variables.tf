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

# Requerida por azurerm_key_vault.main (todo Key Vault necesita saber a
# qué tenant de Azure AD pertenece). Viene de
# data.azurerm_client_config.current.tenant_id en la raíz — se lee
# automáticamente, no hay que pasarla a mano.
variable "tenant_id" {
  description = "Tenant ID de Azure AD"
  type        = string
}

# Usada en azurerm_key_vault_secret.ssh_public_key. Viene de
# data.azurerm_key_vault_secret.ssh_public_key.value en la raíz (el
# secreto ya leído del Key Vault de bootstrap) — este módulo solo la
# recibe y la re-guarda, no la genera.
variable "ssh_public_key" {
  description = "Valor de la SSH public key a guardar como secreto"
  type        = string
  sensitive   = true
}

# Consumida por azurerm_role_assignment.pipeline_secrets_officer (count =
# 1 si no está vacía). Viene de var.pipeline_principal_id en la raíz, que
# a su vez suele llegar como TF_VAR_pipeline_principal_id desde el
# pipeline (ver README > CI/CD).
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
