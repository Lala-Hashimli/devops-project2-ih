# Project 2 Runbook

## 1. Prepare Azure

- Sign in with Azure CLI
- Select the correct subscription
- Make sure the shared Key Vault and certificate still exist

Example:

```bash
az login
az account set --subscription "<subscription-id>"
az keyvault show --name kv-shared-group4c
az keyvault secret show --vault-name kv-shared-group4c --name agw-cert-group4c
```

## 2. Prepare Terraform Variables

Copy `infra/terraform/env/dev.tfvars.example` to `infra/terraform/env/dev.tfvars` and fill in:

- SQL admin username
- SQL admin password
- frontend allowed origin
- existing Key Vault resource ID
- Application Gateway certificate secret ID

## 3. Provision Infrastructure

```bash
cd infra/terraform
terraform init \
  -backend-config="resource_group_name=rg-tfstate-group4c" \
  -backend-config="storage_account_name=tfstategroup4c001" \
  -backend-config="container_name=terraformstate" \
  -backend-config="key=project2.terraform.tfstate"
terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/dev.tfvars"
```

## 4. Build And Push Images

The GitHub Actions workflows build frontend and backend artifacts, then Ansible deploys them to the private VMs from a self-hosted runner that can reach the VNet.

```bash
npm --prefix frontend ci
npm --prefix frontend run build
mvn -f backend/pom.xml -B clean package
```

## 5. Deploy To VMs Manually If Needed

```bash
cd config/ansible
ansible-playbook playbooks/frontend.yml
ansible-playbook playbooks/backend.yml
```

## 6. Validate

- Open the Application Gateway HTTPS endpoint
- Confirm the homepage loads
- Confirm `/api/ingredients` returns `200`
- Confirm `/api/health` returns `UP`
- Place a test order and read it back

## 7. Troubleshooting

### App Gateway unhealthy backend

- check backend probe path `/api/health`
- check VM services with `systemctl status burger-backend` and `systemctl status nginx`
- check NSGs and subnet routing

### Certificate problems

- confirm App Gateway identity has `Key Vault Secrets User`
- confirm the secret ID is versionless
- confirm the certificate is enabled

### SQL connectivity problems

- confirm the private endpoint exists
- confirm `privatelink.database.windows.net` is linked to the VNet
- confirm backend env vars are correct
