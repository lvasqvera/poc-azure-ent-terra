# poc-azure-ent-terra

POC de infraestructura en Azure con Terraform: Resource Group, red (VNet + NSG
+ IP pública), una VM Linux con nginx, un Key Vault con RBAC para la SSH
public key, y un budget mensual con alerta por correo.

Migrado desde una versión previa en Bicep (mismo diseño y mismos hallazgos de
la suscripción) a Terraform, herramienta con la que el autor tiene más
experiencia.

## Arquitectura

```
Resource Group (POC-Entrevista)
├── network
│   ├── NSG   → permite 80 desde Internet, 22 solo desde ssh_source_ip
│   ├── VNet 10.0.0.0/16 + Subnet 10.0.1.0/24
│   └── Public IP (Standard, estática) + NIC
├── keyvault
│   └── Key Vault (RBAC, purge protection) con el secreto ssh-public-key
├── compute
│   └── VM Linux (Ubuntu 22.04, x64 o arm64 según el SKU) + nginx vía cloud-init
└── budget
    └── Budget mensual sobre el Resource Group con alerta por correo
```

La SSH public key **no se genera en este repo**: se lee desde un Key Vault de
bootstrap pre-existente (fuera de este state) y se copia como secreto al Key
Vault del proyecto.

## Levantar y eliminar el proyecto

Referencia rápida para el uso diario, asumiendo que el bootstrap (backend de
state + Key Vault de bootstrap, ver más abajo) y el pipeline (secrets/vars en
GitHub, ver [CI/CD](#cicd-github-actions)) ya están configurados una vez.

### Levantar

El despliegue real corre por el pipeline, no a mano. Si el ambiente no está
levantado (o querés aplicar un cambio), alcanza con mergear/pushear a
`master`:

```bash
git add -A
git commit -m "..."
git push origin master
```

Eso dispara [.github/workflows/terraform.yml](.github/workflows/terraform.yml),
que corre `terraform plan` + `terraform apply` autenticado por OIDC. Podés
seguir el progreso con `gh run watch -R lvasqvera/poc-azure-ent-terra` o en la
pestaña *Actions* del repo.

### Eliminar

El backend remoto no impide `terraform destroy` — al contrario, es lo que lo
hace seguro (mismo state, mismo lock que usa el pipeline). Se corre local,
con las mismas variables requeridas que el `apply`:

```bash
terraform destroy \
  -var="ssh_source_ip=<tu-ip>/32" \
  -var="bootstrap_resource_group_name=<bootstrap-rg>" \
  -var="bootstrap_key_vault_name=<bootstrap-kv>" \
  -var="pipeline_principal_id=<object-id-del-sp>"
```

Purga el Key Vault del proyecto y borra el Resource Group aunque tenga
recursos sueltos (ver `providers.tf`). **No** toca el backend de state ni el
Key Vault de bootstrap — viven fuera de este state a propósito.

> **Nota:** para correr `plan`/`destroy` desde tu propia máquina (no desde el
> pipeline) tu usuario necesita el rol **Key Vault Secrets Officer** sobre el
> Key Vault *del proyecto* — no solo sobre el de bootstrap — porque Terraform
> refresca el secreto `ssh-public-key` ahí antes de poder planificar. Si no
> lo tenés (típicamente porque hasta ahora solo aplicó el pipeline), otorgátelo:
> ```bash
> az role assignment create \
>   --assignee "$(az ad signed-in-user show --query id -o tsv)" \
>   --role "Key Vault Secrets Officer" \
>   --scope "$(az keyvault show --name <nombre-kv-del-proyecto> --query id -o tsv)"
> ```

## Prerrequisitos

- Terraform >= 1.9
- Azure CLI autenticado (`az login`) para uso local, o un Service Principal
  con federación OIDC para el pipeline (ver [CI/CD](#cicd-github-actions))
- Los dos recursos de bootstrap descritos abajo, creados manualmente una sola
  vez, **fuera** de este state (mismo problema de huevo-y-gallina que en la
  versión Bicep: Terraform no puede gestionar el storage account donde guarda
  su propio state, ni depender de un Key Vault que él mismo crea).

### Bootstrap del backend de estado

Storage Account con RBAC (sin claves compartidas) y versionado de blobs
habilitado, creado una única vez:

```bash
az group create -n poc-entrevista-tfstate-rg -l centralindia

az storage account create \
  -n pocentrevistatf9f62ab \
  -g poc-entrevista-tfstate-rg \
  -l centralindia \
  --sku Standard_LRS \
  --allow-shared-key-access false

az storage account blob-service-properties update \
  --account-name pocentrevistatf9f62ab \
  --enable-versioning true

az storage container create \
  --account-name pocentrevistatf9f62ab \
  --name tfstate \
  --auth-mode login
```

Quien ejecute `terraform plan`/`apply` (usuario local o el Service Principal
OIDC del pipeline) necesita el rol **Storage Blob Data Contributor** sobre
esta storage account.

### Bootstrap del Key Vault (fuente de la SSH key)

Un Key Vault pre-existente con un secreto `ssh-public-key`:

```bash
az keyvault create -n <bootstrap-kv-name> -g <bootstrap-rg-name> -l centralindia

az keyvault secret set \
  --vault-name <bootstrap-kv-name> \
  --name ssh-public-key \
  --value "$(cat ~/.ssh/id_ed25519.pub)"
```

Quien ejecute Terraform necesita el rol **Key Vault Secrets User** sobre este
vault de bootstrap.

## Variables

| Variable | Requerida | Descripción |
|---|---|---|
| `ssh_source_ip` | Sí | CIDR (ej. `203.0.113.10/32`) permitido para SSH. Único valor que hay que completar manualmente antes de desplegar. |
| `bootstrap_resource_group_name` | Sí | RG del Key Vault de bootstrap. |
| `bootstrap_key_vault_name` | Sí | Nombre del Key Vault de bootstrap. |
| `pipeline_principal_id` | No | Object ID del Service Principal OIDC del pipeline. Vacío = no se crea el role assignment "Key Vault Secrets Officer" en el Key Vault del proyecto — necesario porque es el propio pipeline quien escribe el secreto `ssh-public-key` ahí en cada apply, no solo lo lee. |
| `location`, `name_prefix`, `resource_group_name`, `vm_size`, `admin_username`, `budget_amount`, `budget_threshold_percentage`, `contact_emails` | No | Tienen default, ver [variables.tf](variables.tf). |

Pasá los valores requeridos con `-var`, un `*.tfvars` (ignorado por git) o
variables de entorno `TF_VAR_*`.

### Fallback de SKU sin cuota

El default (`Standard_B1s`, x64) puede no tener cuota disponible en algunas
suscripciones nuevas. Si `terraform apply` falla por cuota, usar:

```bash
terraform apply -var="vm_size=Standard_B2ats_v2"
```

Es un SKU arm64 (Ampere Altra); el módulo `compute` detecta la arquitectura
por el nombre del SKU y ajusta sola la imagen de Ubuntu.

## Deploy local

```bash
terraform init
terraform plan \
  -var="ssh_source_ip=<tu-ip>/32" \
  -var="bootstrap_resource_group_name=<bootstrap-rg>" \
  -var="bootstrap_key_vault_name=<bootstrap-kv>"
terraform apply <mismas -var>
```

## CI/CD (GitHub Actions)

El workflow [.github/workflows/terraform.yml](.github/workflows/terraform.yml)
corre `terraform plan` en cada Pull Request contra `master`, y
`plan` + `apply` en cada push a `master`. Se autentica contra Azure vía OIDC
(sin secretos de larga duración).

### Configurar el Service Principal OIDC

```bash
az ad app create --display-name poc-entrevista-gha

APP_ID=$(az ad app list --display-name poc-entrevista-gha --query "[0].appId" -o tsv)
az ad sp create --id "$APP_ID"

az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "poc-entrevista-master",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:lvasqvera/poc-azure-ent-terra:ref:refs/heads/master",
  "audiences": ["api://AzureADTokenExchange"]
}'

az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "poc-entrevista-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:lvasqvera/poc-azure-ent-terra:pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Rol sobre la suscripción/RG destino, el storage account de state, y
# "Key Vault Secrets User" sobre el KV de bootstrap.
az role assignment create --assignee "$APP_ID" --role Contributor \
  --scope /subscriptions/<subscription-id>
```

### Secretos/variables del repo

En *Settings → Secrets and variables → Actions* del repo:

| Nombre | Tipo | Valor |
|---|---|---|
| `AZURE_CLIENT_ID` | secret | `appId` del Service Principal |
| `AZURE_TENANT_ID` | secret | Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | secret | Subscription ID destino |
| `TF_VAR_SSH_SOURCE_IP` | secret | Tu IP pública en formato CIDR |
| `TF_VAR_BOOTSTRAP_RESOURCE_GROUP_NAME` | variable | RG del Key Vault de bootstrap |
| `TF_VAR_BOOTSTRAP_KEY_VAULT_NAME` | variable | Nombre del Key Vault de bootstrap |
| `TF_VAR_PIPELINE_PRINCIPAL_ID` | variable | Object ID (no el appId) del Service Principal, para el role assignment sobre el KV del proyecto |

GitHub Actions expone las variables de entorno en minúsculas/mayúsculas tal
cual se definan; Terraform lee `TF_VAR_<nombre_en_minúsculas>`, por eso los
nombres arriba respetan el casing exacto que espera Terraform.

## Destruir el ambiente

```bash
terraform destroy <mismas -var que en apply>
```

- El Key Vault del proyecto se purga en vez de quedar soft-deleted
  (`purge_soft_delete_on_destroy` en `providers.tf`).
- El Resource Group se borra aunque tenga recursos no gestionados por este
  state (`prevent_deletion_if_contains_resources = false`).
- El backend de estado (RG + Storage Account de bootstrap) y el Key Vault de
  bootstrap **no** se destruyen con este comando: viven fuera de este state
  a propósito.

## Costo

Budget mensual configurado en `$5` (`budget_amount`), con alerta al 80% de
uso (`budget_threshold_percentage`) a los correos en `contact_emails`.
