# Este archivo es el "orquestador": no crea recursos de infraestructura él
# mismo (salvo el Resource Group), sino que arma los valores de entrada
# (variables, data sources, tags) y se los pasa a cada módulo. Cada módulo
# en ./modules/* crea sus propios recursos y devuelve outputs que otros
# módulos consumen (ej. la NIC de "network" la usa "compute" para la VM).

# Data source (no crea nada, solo LEE): obtiene el tenant_id de la
# suscripción actualmente autenticada (la de quien corre terraform). Se usa
# más abajo para el módulo keyvault, que lo necesita al crear el Key Vault.
data "azurerm_client_config" "current" {}

# Data source: apunta al Key Vault de BOOTSTRAP (pre-existente, fuera de
# este state — ver README). "bootstrap_key_vault_name" y
# "bootstrap_resource_group_name" son variables sin default: hay que
# pasarlas a mano (-var, TF_VAR_*, etc.), apuntando al vault donde
# guardaste tu SSH public key de antemano.
#
# A diferencia de Bicep (que necesitaba az.getSecret() + enabledForTemplate
# Deployment por un problema de resolución server-side vía un servicio
# first-party de ARM), en Terraform esto es simplemente un data source
# normal: lo resuelve la misma identidad que corre `terraform plan`/`apply`
# (el usuario local o el Service Principal OIDC del pipeline), y por eso
# solo necesita el rol "Key Vault Secrets User" directo sobre el vault de
# bootstrap — sin vueltas.
data "azurerm_key_vault" "bootstrap" {
  name                = var.bootstrap_key_vault_name
  resource_group_name = var.bootstrap_resource_group_name
}

# Data source: LEE el secreto "ssh-public-key" de ese vault de bootstrap.
# Su valor (.value) se reutiliza más abajo en dos lugares: se copia como
# secreto en el Key Vault del proyecto (module.keyvault) y se inyecta como
# credencial de acceso SSH en la VM (module.compute) — nunca se escribe en
# texto plano en ningún .tf ni .tfvars.
data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-public-key"
  key_vault_id = data.azurerm_key_vault.bootstrap.id
}

# El único recurso "raíz" que no vive dentro de un módulo: el Resource
# Group donde va a vivir TODO lo demás (red, VM, Key Vault del proyecto,
# budget). Su nombre viene de la variable resource_group_name (default
# "POC-Entrevista").
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = local.tags
}

# Tags comunes que se propagan a todos los recursos (vía el parámetro
# "tags" de cada módulo) para identificar qué pertenece a este POC.
locals {
  tags = {
    project     = "poc-entrevista"
    managed_by  = "terraform"
    environment = "demo"
  }
}

# Módulo network (./modules/network/main.tf): crea el NSG (reglas de
# firewall — 80 abierto a Internet, 22 solo desde ssh_source_ip), la VNet,
# la Subnet, la IP pública y la NIC. Expone la NIC (nic_id) para que
# "compute" se la asigne a la VM.
module "network" {
  source = "./modules/network"

  location            = var.location
  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  ssh_source_ip       = var.ssh_source_ip
  tags                = local.tags
}

# Módulo keyvault (./modules/keyvault/main.tf): crea el Key Vault DEL
# PROYECTO (distinto del de bootstrap) con RBAC, y le copia adentro el
# mismo secreto ssh-public-key leído arriba — queda versionado/auditado
# junto con el resto de los recursos del POC. pipeline_principal_id (si se
# pasa) hace que el pipeline reciba permiso de escritura sobre este vault.
module "keyvault" {
  source = "./modules/keyvault"

  location              = var.location
  name_prefix           = var.name_prefix
  resource_group_name   = azurerm_resource_group.main.name
  tenant_id             = data.azurerm_client_config.current.tenant_id
  ssh_public_key        = data.azurerm_key_vault_secret.ssh_public_key.value
  pipeline_principal_id = var.pipeline_principal_id
  tags                  = local.tags
}

# Módulo compute (./modules/compute/main.tf): crea la VM Linux (Ubuntu),
# le instala nginx vía cloud-init, y le inyecta la SSH public key como
# única forma de acceso (sin password). Usa la NIC que expone el módulo
# network (module.network.nic_id) — por eso Terraform crea primero la red
# y recién después la VM.
module "compute" {
  source = "./modules/compute"

  location             = var.location
  name_prefix          = var.name_prefix
  resource_group_name  = azurerm_resource_group.main.name
  admin_username       = var.admin_username
  vm_size              = var.vm_size
  network_interface_id = module.network.nic_id
  ssh_public_key       = data.azurerm_key_vault_secret.ssh_public_key.value
  tags                 = local.tags
}

# Módulo budget (./modules/budget/main.tf): crea la alerta de costo mensual
# sobre el Resource Group completo (resource_group_id), con email cuando se
# cruza el umbral. No depende de red/compute/keyvault, solo del RG — por
# eso es el único módulo sin "tags" (los budgets de Consumption no las
# soportan) y el que menos variables recibe.
module "budget" {
  source = "./modules/budget"

  name_prefix                 = var.name_prefix
  resource_group_id           = azurerm_resource_group.main.id
  budget_amount               = var.budget_amount
  budget_threshold_percentage = var.budget_threshold_percentage
  contact_emails              = var.contact_emails
}
