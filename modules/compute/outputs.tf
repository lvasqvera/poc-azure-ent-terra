# Consumido por outputs.tf (raíz) como vm_name.
output "vm_name" {
  value = azurerm_linux_virtual_machine.main.name
}

# No se consume dentro de este proyecto hoy; queda expuesto por si algún
# otro recurso necesita referenciar la VM (ej. una extensión o un alerting
# scoped a este resource ID puntual).
output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}
