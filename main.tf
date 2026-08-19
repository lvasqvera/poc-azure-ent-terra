data "azurerm_client_config" "current" {}

# Key Vault de bootstrap (pre-existente, fuera de este estado): fuente de la
# SSH public key. A diferencia de Bicep (que necesitaba az.getSecret() +
# enabledForTemplateDeployment por un problema de resolución server-side vía
# un servicio first-party de ARM), en Terraform esto es simplemente un data
# source normal: lo resuelve la misma identidad que corre `terraform plan`/
# `apply` (el usuario local o el Service Principal OIDC del pipeline), y por
# eso solo necesita el rol "Key Vault Secrets User" directo sobre el vault
# de bootstrap — sin vueltas.
data "azurerm_key_vault" "bootstrap" {
  name                = var.bootstrap_key_vault_name
  resource_group_name = var.bootstrap_resource_group_name
}

data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-public-key"
  key_vault_id = data.azurerm_key_vault.bootstrap.id
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = local.tags
}

locals {
  tags = {
    project     = "poc-entrevista"
    managed_by  = "terraform"
    environment = "demo"
  }
}

module "network" {
  source = "./modules/network"

  location            = var.location
  name_prefix         = var.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  ssh_source_ip       = var.ssh_source_ip
  tags                = local.tags
}

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

module "budget" {
  source = "./modules/budget"

  name_prefix                 = var.name_prefix
  resource_group_id           = azurerm_resource_group.main.id
  budget_amount               = var.budget_amount
  budget_threshold_percentage = var.budget_threshold_percentage
  contact_emails              = var.contact_emails
}
