# No se consume dentro de este proyecto hoy (main.tf raíz no lo re-expone
# en su outputs.tf); útil igual para inspeccionar con `terraform state
# show`/`terraform output -module`.
output "budget_name" {
  value = azurerm_consumption_budget_resource_group.main.name
}
