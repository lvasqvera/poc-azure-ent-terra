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

variable "vm_size" {
  description = "SKU de la VM"
  type        = string
}

variable "network_interface_id" {
  description = "Resource ID de la NIC a asociar a la VM"
  type        = string
}

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
