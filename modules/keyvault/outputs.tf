# Consumido por outputs.tf (raíz) como key_vault_name — el valor que se
# muestra al terminar el apply/plan para saber cómo se llamó el vault
# (tiene un sufijo random, no es predecible de antemano).
output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

# No se consume dentro de este proyecto hoy; queda expuesto por si algún
# otro módulo necesita referenciar el vault (ej. un role assignment extra).
output "key_vault_id" {
  value = azurerm_key_vault.main.id
}
