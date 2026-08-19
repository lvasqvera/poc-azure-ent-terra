terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # Backend remoto: Storage Account con RBAC (sin claves compartidas,
  # use_oidc para autenticar igual que el provider) y versionado de blobs
  # habilitado. Se crea UNA sola vez, fuera de este mismo estado (ver
  # README > "Bootstrap del backend de estado") — el mismo problema de
  # huevo-y-gallina que ya resolvimos en la version Bicep con el Key Vault
  # de bootstrap: Terraform no puede gestionar el storage account donde
  # guarda su propio estado.
  backend "azurerm" {
    resource_group_name  = "poc-entrevista-tfstate-rg"
    storage_account_name = "pocentrevistatf9f62ab"
    container_name       = "tfstate"
    key                  = "poc-entrevista.tfstate"
    use_azuread_auth     = true
    use_oidc             = true
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Permite que `terraform destroy` purgue el Key Vault del proyecto en
      # vez de dejarlo soft-deleted. Ver README > "Destruir el ambiente".
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # Evita que Terraform se niegue a borrar el RG si quedara algun
      # recurso no gestionado por el mismo estado dentro de el.
      prevent_deletion_if_contains_resources = false
    }
  }

  use_oidc = true
}
