# NSG (firewall a nivel de subnet): decide qué tráfico entrante se permite.
# Se asocia a la subnet más abajo (azurerm_subnet_network_security_group_
# association). Las reglas se evalúan por "priority" (menor = primero).
resource "azurerm_network_security_group" "main" {
  name                = "${var.name_prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-TrustedIP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_ip
    destination_address_prefix = "*"
  }

  # Deny explícito para el resto de Internet en el puerto 22. El NSG ya
  # deniega todo por defecto (DenyAllInBound, prioridad 65500), pero esta
  # regla lo hace explícito y auditable, y evita que una futura regla
  # "Allow *" agregada sin cuidado reabra SSH accidentalmente.
  security_rule {
    name                       = "Deny-SSH-Internet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# Red virtual del proyecto: un único espacio de direcciones privado
# (10.0.0.0/16) que contiene la subnet de abajo. Es el "contenedor" de red;
# no tiene reglas de tráfico propias (eso lo maneja el NSG).
resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subred dentro de la VNet (10.0.1.0/24) donde vive la NIC de la VM.
resource "azurerm_subnet" "public" {
  name                 = "${var.name_prefix}-subnet-public"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Sin esta asociación explícita, el NSG de arriba quedaría creado pero
# "desconectado" — no filtraría nada. Este recurso es el que efectivamente
# aplica las reglas del NSG a todo lo que esté en la subnet.
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# IP pública fija (Static, no cambia si se reinicia la VM) que se asigna a
# la NIC de abajo. SKU "Standard" porque es el único compatible con
# allocation_method "Static" en un NIC (el SKU "Basic" está deprecado).
resource "azurerm_public_ip" "main" {
  name                = "${var.name_prefix}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# NIC (tarjeta de red): lo que efectivamente conecta la VM (creada en el
# módulo compute, ver network_interface_id) a la subnet y a la IP pública.
# El módulo compute no crea su propia NIC — la recibe como variable
# (network_interface_id = module.network.nic_id en main.tf de la raíz).
resource "azurerm_network_interface" "main" {
  name                = "${var.name_prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}
