# Standard_B2ats_v2 es una SKU arm64 (Ampere Altra); Standard_B1s es x64.
# Detectamos la arquitectura a partir del nombre de la SKU para elegir
# automáticamente la imagen de Ubuntu correcta sin exigir una variable
# extra — mismo mecanismo que en la versión Bicep, ya validado en un
# deploy real.
locals {
  is_arm64  = strcontains(lower(var.vm_size), "ats")
  image_sku = local.is_arm64 ? "22_04-lts-arm64" : "22_04-lts-gen2"
}

# Este es el recurso que levanta la VM en sí — el "servidor" del POC. Todo
# lo demás en el proyecto (red, Key Vault, budget) existe para soportarla
# o monitorearla.
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.name_prefix}-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  # La NIC no la crea este módulo: la recibe ya creada del módulo network
  # (network_interface_id = module.network.nic_id, pasado desde main.tf
  # raíz). Es lo que le da su IP privada/pública y la conecta a la subnet.
  network_interface_ids = [var.network_interface_id]

  # Autenticación solo por SSH key — sin password.
  disable_password_authentication = true

  # La credencial de acceso: var.ssh_public_key llega desde main.tf raíz
  # como data.azurerm_key_vault_secret.ssh_public_key.value (el mismo
  # valor que también termina copiado en el Key Vault del proyecto).
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  # Disco del sistema operativo. Standard_LRS (HDD) alcanza para un POC de
  # $5/mes; no hace falta Premium SSD.
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Qué imagen de Ubuntu instalar. sku sale de local.image_sku (arriba),
  # que cambia sola entre x64 y arm64 según var.vm_size.
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = local.image_sku
    version   = "latest"
  }

  # Script de arranque (cloud-init.yaml, mismo directorio) que instala y
  # prende nginx la primera vez que bootea la VM — ver ese archivo.
  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
}
