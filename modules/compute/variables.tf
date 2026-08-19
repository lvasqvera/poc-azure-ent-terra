variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo usado para nombrar los recursos"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group donde se crea la VM"
  type        = string
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
}

# Determina el local.is_arm64/image_sku en main.tf (¿es un SKU "ats" —
# arm64 — o no?) y se pasa directo como size de la VM.
variable "vm_size" {
  description = "SKU de la VM"
  type        = string
}

# Viene de module.network.nic_id en main.tf raíz — la NIC ya creada por el
# módulo network, este módulo no crea la suya propia.
variable "network_interface_id" {
  description = "Resource ID de la NIC a asociar a la VM"
  type        = string
}

# Viene de data.azurerm_key_vault_secret.ssh_public_key.value en main.tf
# raíz (leída del Key Vault de bootstrap). Se usa en el bloque
# admin_ssh_key de azurerm_linux_virtual_machine.main.
variable "ssh_public_key" {
  description = "SSH public key inyectada como credencial de acceso (nunca password)"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags aplicados a los recursos"
  type        = map(string)
  default     = {}
}
