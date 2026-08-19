variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo usado para nombrar los recursos"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group donde se crean los recursos"
  type        = string
}

variable "ssh_source_ip" {
  description = "IP pública de origen (CIDR) permitida para SSH"
  type        = string
}

variable "tags" {
  description = "Tags aplicados a los recursos"
  type        = map(string)
  default     = {}
}
