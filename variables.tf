variable "location" {
  description = "Región de Azure para todos los recursos"
  type        = string
  default     = "centralindia"
}

variable "name_prefix" {
  description = "Prefijo usado para nombrar los recursos"
  type        = string
  default     = "poc-entrevista"
}

variable "resource_group_name" {
  description = "Nombre del Resource Group del proyecto"
  type        = string
  default     = "POC-Entrevista"
}

variable "ssh_source_ip" {
  description = "IP pública de origen (CIDR, ej. \"203.0.113.10/32\") permitida para SSH. Único valor que debes completar manualmente antes de desplegar (ver README)."
  type        = string
}

variable "bootstrap_resource_group_name" {
  description = "Resource group del Key Vault de bootstrap (fuente de la SSH public key, ver README > Bootstrap)"
  type        = string
}

variable "bootstrap_key_vault_name" {
  description = "Nombre del Key Vault de bootstrap (fuente de la SSH public key)"
  type        = string
}

variable "vm_size" {
  description = "SKU de la VM. Fallback documentado en README si no hay cuota: Standard_B2ats_v2 (arm64, la imagen se ajusta sola)"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
  default     = "azureuser"
}

variable "budget_amount" {
  description = "Monto mensual del budget en USD"
  type        = number
  default     = 5
}

variable "budget_threshold_percentage" {
  description = "Umbral de alerta del budget, en porcentaje"
  type        = number
  default     = 80
}

variable "contact_emails" {
  description = "Correos a notificar en la alerta de budget"
  type        = list(string)
  default     = ["lvasqvera@gmail.com"]
}

variable "pipeline_principal_id" {
  description = "Object ID (principalId) del Service Principal OIDC del pipeline. Vacío = no se crea el role assignment \"Key Vault Secrets Officer\" en el Key Vault del proyecto (y el propio pipeline no podría escribir el secreto ssh-public-key ahí)."
  type        = string
  default     = ""
}
