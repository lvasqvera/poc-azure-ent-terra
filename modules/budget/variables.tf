variable "name_prefix" {
  description = "Prefijo usado para nombrar los recursos"
  type        = string
}

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
