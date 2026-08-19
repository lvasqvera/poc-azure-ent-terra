# Todas estas variables las pasa main.tf (raíz) al declarar
# `module "network" { ... }` — no tienen default porque este módulo no se
# usa nunca de forma aislada, siempre a través de la raíz.

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

# Usada en la regla "Allow-SSH-TrustedIP" del NSG (main.tf): es el ÚNICO
# origen desde el que se permite el puerto 22. Viene de var.ssh_source_ip
# en la raíz, que no tiene default — hay que pasarla a mano.
variable "ssh_source_ip" {
  description = "IP pública de origen (CIDR) permitida para SSH"
  type        = string
}

variable "tags" {
  description = "Tags aplicados a los recursos"
  type        = map(string)
  default     = {}
}
