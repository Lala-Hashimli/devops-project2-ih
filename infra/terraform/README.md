# Terraform Infrastructure

This folder provisions the Azure VM-based infrastructure for Project 2 using Terraform.

## What it creates

- Resource group
- Virtual network and four subnets
- Log Analytics workspace
- Application Insights
- Azure Container Registry
- Azure SQL Server and database
- SQL private endpoint and private DNS
- Frontend VM on a private subnet
- Backend VM on a private subnet
- Application Gateway WAF v2 with HTTPS on port 443
- Three Azure Monitor alerts

## External dependency

The configuration expects an existing shared Key Vault certificate:

- Key Vault: `kv-shared-group4c`
- Certificate secret ID: `https://kv-shared-group4c.vault.azure.net/secrets/agw-cert-group4c/`

Terraform assigns the Application Gateway managed identity the `Key Vault Secrets User` role on that vault so the listener can read the certificate.

## Recommended init

Use remote state stored in Azure Storage and pass the backend details during init:

```bash
terraform init \
  -backend-config="resource_group_name=rg-tfstate-group4c" \
  -backend-config="storage_account_name=tfstategroup4c001" \
  -backend-config="container_name=terraformstate" \
  -backend-config="key=project2.terraform.tfstate"
```

## Example workflow

```bash
cp env/dev.tfvars.example env/dev.tfvars
terraform fmt -recursive
terraform validate
terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/dev.tfvars"
```
