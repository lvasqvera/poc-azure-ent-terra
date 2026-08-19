# Standard_B2ats_v2 es una SKU arm64 (Ampere Altra); Standard_B1s es x64.
# Detectamos la arquitectura a partir del nombre de la SKU para elegir
# automáticamente la imagen de Ubuntu correcta sin exigir una variable
# extra — mismo mecanismo que en la versión Bicep, ya validado en un
# deploy real.
locals {
  is_arm64  = strcontains(lower(var.vm_size), "ats")
  image_sku = local.is_arm64 ? "22_04-lts-arm64" : "22_04-lts-gen2"
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.name_prefix}-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [var.network_interface_id]

  # Autenticación solo por SSH key — sin password.
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = local.image_sku
    version   = "latest"
  }

  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
}
