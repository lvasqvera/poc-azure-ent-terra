# Estos 4 valores son los que se imprimen al final de un `terraform apply`
# (y se pueden volver a ver con `terraform output`). Cada uno solo
# reenvía un output que ya expone el módulo correspondiente — no calculan
# nada nuevo acá.

output "resource_group_name" {
  description = "Nombre del Resource Group creado"
  value       = azurerm_resource_group.main.name
}

output "key_vault_name" {
  description = "Nombre del Key Vault del proyecto"
  value       = module.keyvault.key_vault_name
}

output "vm_name" {
  description = "Nombre de la VM"
  value       = module.compute.vm_name
}

output "vm_public_ip" {
  description = "IP pública de la VM"
  value       = module.network.public_ip_address
}
