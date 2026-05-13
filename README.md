# Project 2 | Secure 3-Tier Burger Builder on Azure

This repository rebuilds Project 2 as a production-style Azure VM deployment with:

- React + Vite frontend
- Spring Boot backend
- Azure SQL Database with private endpoint
- Azure Linux virtual machines for frontend and backend
- Azure Application Gateway WAF v2 as the only public entry point
- Terraform for infrastructure
- GitHub Actions for CI/CD
- Ansible reserved for SonarQube automation

The Telegram bot is intentionally out of scope for this repository.

## Architecture

The final request flow is:

`Browser -> Application Gateway (HTTPS 443) -> Frontend VM / Backend VM (private) -> Azure SQL (private endpoint)`

- `/` routes to the frontend VM
- `/api/*` routes to the backend VM
- only Application Gateway has a public IP
- compute and database stay private

Architecture diagram: [architecture-diagram.svg](docs/architecture-diagram.svg)

## Repository Layout

```text
frontend/                  React app
backend/                   Spring Boot API
infra/terraform/           Azure infrastructure as code
config/ansible/            SonarQube automation support
.github/workflows/         Infra, frontend, backend, and DAST pipelines
docs/                      Runbook and diagram
```

## What Was Added Or Changed

- Added Dockerfiles for frontend and backend
- Added Terraform to recreate the Azure environment from scratch
- Updated frontend API config for gateway-based routing
- Updated backend CORS to use configured origins instead of `*`
- Replaced old workflows with VM-based Ansible deployments
- Added a runbook and architecture documentation

## Azure Naming

All Azure resource names end with `group4c`, for example:

- `rg-devops-p2-group4c`
- `vnet-devops-p2-group4c`
- `vm-frontend-group4c`
- `vm-backend-group4c`
- `agw-devops-p2-group4c`
- `sqlsrvdevopsp2group4c`

## Region

Default region in Terraform is `Canada Central`, which avoids the blocked regions listed in the project instructions.

## Prerequisites

- Azure subscription with permissions to create networking, SQL, Monitor, VM, and App Gateway resources
- Azure CLI
- Terraform 1.7+
- Docker
- Java 21
- Node.js 22
- Maven 3.9+
- Existing shared Key Vault certificate:
  - Key Vault: `kv-shared-group4c`
  - Certificate secret ID: `https://kv-shared-group4c.vault.azure.net/secrets/agw-cert-group4c/`

## Local App Notes

### Frontend

The frontend now reads `VITE_API_BASE_URL`.

- local development can use `http://localhost:8080`
- production can rely on same-origin gateway routing

### Backend

The backend reads `CORS_ALLOWED_ORIGINS` and maps it into:

- `app.cors.allowed-origins`

For production, set it to your gateway hostname, for example:

```env
CORS_ALLOWED_ORIGINS=https://burger.group4c.local
```

## Infrastructure

Terraform files live in [infra/terraform](infra/terraform).

Create `env/dev.tfvars` from the example:

```bash
cd infra/terraform
cp env/dev.tfvars.example env/dev.tfvars
```

Update:

- `db_admin_username`
- `db_admin_password`
- `frontend_allowed_origin`
- `vm_admin_username`
- `vm_admin_password`
- `existing_key_vault_id`
- `app_gateway_certificate_secret_id`

Initialize remote state:

```bash
terraform init \
  -backend-config="resource_group_name=rg-tfstate-group4c" \
  -backend-config="storage_account_name=tfstategroup4c001" \
  -backend-config="container_name=terraformstate" \
  -backend-config="key=project2.terraform.tfstate"
```

Deploy:

```bash
terraform fmt -recursive
terraform validate
terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/dev.tfvars"
```

## Build Artifacts

Frontend:

```bash
docker build -t burger-frontend-group4c ./frontend
```

Backend:

```bash
docker build -t burger-backend-group4c ./backend
```

## GitHub Actions

Pipelines:

- `.github/workflows/infra.yml`
- `.github/workflows/frontend.yml`
- `.github/workflows/backend.yml`
- `.github/workflows/dast-scan.yml`

Required GitHub secrets:

- `AZURE_CREDENTIALS`
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`
- `TFSTATE_RESOURCE_GROUP`
- `TFSTATE_STORAGE_ACCOUNT`
- `TFSTATE_CONTAINER`
- `TFSTATE_KEY`
- `SQL_ADMIN_USERNAME`
- `SQL_DB_PASSWORD`
- `VM_ADMIN_USERNAME`
- `VM_ADMIN_PASSWORD`
- `APP_GATEWAY_HOSTNAME`
- `APP_GATEWAY_CERT_SECRET_ID`
- `APP_GATEWAY_KEY_VAULT_ID`
- `FRONTEND_API_BASE_URL`
- `APP_GATEWAY_URL`

## Validation Checklist

- `https://<gateway-host>/` loads the frontend
- `https://<gateway-host>/api/ingredients` returns backend data
- frontend and backend are not publicly exposed directly
- Azure SQL public network access is disabled
- backend writes and reads records from SQL
- App Gateway health probe is green
- alerts exist for App Gateway, backend CPU, and SQL CPU

## Runbook

Operational steps are documented in [runbook.md](docs/runbook.md).
