output "nic_id" {
  value = azurerm_network_interface.main.id
}

output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_id" {
  value = azurerm_subnet.public.id
}
