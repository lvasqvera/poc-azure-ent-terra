terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

# Nombre de Key Vault: máx 24 caracteres, alfanumérico + guiones, único
# globalmente. random_id da el sufijo (equivalente al uniqueString() de Bicep).
resource "random_id" "kv_suffix" {
  byte_length = 4
}

locals {
  key_vault_name = substr(
    "${replace(var.name_prefix, "-", "")}kv${random_id.kv_suffix.hex}",
    0,
    24
  )
}

resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  # RBAC en vez de access policies legacy, tal como exige el ejercicio.
  rbac_authorization_enabled = true

  soft_delete_retention_days = 7

  # Esta suscripción exige purge protection habilitada en todo Key Vault
  # nuevo (rechaza el create con purge_protection_enabled = false) — mismo
  # hallazgo que en la versión Bicep. `terraform destroy` igual puede
  # purgarlo gracias a purge_soft_delete_on_destroy en el provider (providers.tf).
  purge_protection_enabled = true

  # Acceso público habilitado a propósito: vault de demo sin Private
  # Endpoint (fuera de alcance para un POC de $5/mes). El acceso real está
  # protegido por RBAC (enable_rbac_authorization), no por red.
  public_network_access_enabled = true
}


# El pipeline necesita permiso de ESCRITURA (no solo lectura) sobre este
# vault puntual: es él mismo quien crea/actualiza el secreto de abajo en
# cada apply (Terraform reconcilia azurerm_key_vault_secret como cualquier
# otro recurso, no es un valor de solo-lectura). Sigue acotado a este vault
# puntual, nada de administración del vault ni acceso a otros recursos.
resource "azurerm_role_assignment" "pipeline_secrets_officer" {
  count                = var.pipeline_principal_id != "" ? 1 : 0
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.pipeline_principal_id

  # La API de Microsoft.Authorization devuelve el scope de un role
  # assignment normalizado en minusculas, distinto de como Terraform lo
  # genera (azurerm_key_vault.main.id, con el casing real del resource
  # group). Sin este ignore_changes, cada apply detecta ese "drift" y
  # fuerza destruir y recrear el role assignment innecesariamente.
  lifecycle {
    ignore_changes = [scope]
  }
}

# El RBAC de Azure es eventualmente consistente: sin esta espera, el primer
# apply que crea el vault y el role assignment de arriba en la misma
# corrida falla intermitentemente al escribir el secreto justo después
# (403 ForbiddenByRbac, la propagación todavía no llegó al plano de datos).
resource "time_sleep" "kv_rbac_propagation" {
  count           = var.pipeline_principal_id != "" ? 1 : 0
  depends_on      = [azurerm_role_assignment.pipeline_secrets_officer]
  create_duration = "90s"
}

resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-public-key"
  value        = var.ssh_public_key
  key_vault_id = azurerm_key_vault.main.id
  content_type = "ssh-public-key"

  depends_on = [time_sleep.kv_rbac_propagation]
}
