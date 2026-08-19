# Consumido por main.tf (raíz) → module.compute como network_interface_id,
# para que la VM se conecte a esta NIC.
output "nic_id" {
  value = azurerm_network_interface.main.id
}

# Consumido por outputs.tf (raíz) como vm_public_ip — es lo que se muestra
# al terminar el apply/plan para saber a qué IP conectarse por SSH/HTTP.
output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}

# No se consume dentro de este proyecto todavía; queda expuesto por si en
# el futuro hace falta crear más subnets/recursos en la misma VNet.
output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

# Igual que vnet_id: expuesto para uso futuro (ej. otra VM en la misma
# subnet), no consumido por ningún otro módulo hoy.
output "subnet_id" {
  value = azurerm_subnet.public.id
}
