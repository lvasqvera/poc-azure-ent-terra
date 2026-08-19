# Todas las variables de este módulo vienen de main.tf raíz con el mismo
# nombre (var.budget_amount, var.contact_emails, etc. — ver variables.tf de
# la raíz), que a su vez tienen default salvo resource_group_id.

variable "name_prefix" {
  description = "Prefijo usado para nombrar los recursos"
  type        = string
}

# Viene de azurerm_resource_group.main.id en la raíz — no es una variable
# con default, se resuelve sola una vez que Terraform crea el RG.
variable "resource_group_id" {
  description = "Resource ID del resource group a monitorear"
  type        = string
}

variable "budget_amount" {
  description = "Monto mensual del budget en USD"
  type        = number
}

variable "budget_threshold_percentage" {
  description = "Umbral de alerta del budget, en porcentaje"
  type        = number
}

variable "contact_emails" {
  description = "Correos a notificar cuando se cruza el umbral"
  type        = list(string)
}
