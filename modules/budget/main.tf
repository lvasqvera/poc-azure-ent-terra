# Fechas fijas (no timestamp()/formatdate en tiempo de apply): un budget
# mensual no necesita renovarse, y usar timestamp() generaría un diff
# espurio en cada `terraform plan` solo por la hora de ejecución. Se puede
# correr este valor manualmente si algún día hace falta extenderlo.
locals {
  budget_start_date = "2026-08-01T00:00:00Z"
  budget_end_date   = "2036-08-01T00:00:00Z"
}

# La alerta de costo del POC: NO crea ningún recurso "visible" ni frena
# gastos por sí sola, solo manda un email cuando el gasto acumulado del mes
# sobre resource_group_id cruza el umbral. Es un recurso de Cost
# Management, no un recurso ARM normal — no aparece en la lista de recursos
# del Resource Group en el portal; hay que buscarlo en
# "Cost Management + Billing" → Budgets, o desde el propio RG → sección
# "Cost Management" en el menú izquierdo.
resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "${var.name_prefix}-monthly-budget"
  resource_group_id = var.resource_group_id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = local.budget_start_date
    end_date   = local.budget_end_date
  }

  # Una sola condición de alerta: dispara cuando el gasto REAL (no
  # proyectado) llega o supera threshold_percentage del amount de arriba.
  notification {
    enabled        = true
    threshold      = var.budget_threshold_percentage
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = var.contact_emails
  }
}
