variable "location" {
  description = "Azure region for the project resources."
  type        = string
  default     = "canadacentral"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "name_suffix" {
  description = "Naming suffix required by the project."
  type        = string
  default     = "group4c"
}

variable "address_space" {
  description = "Address space for the shared project VNet."
  type        = string
  default     = "10.40.0.0/16"
}

variable "appgw_subnet_prefix" {
  description = "Subnet for Application Gateway."
  type        = string
  default     = "10.40.1.0/24"
}

variable "frontend_subnet_prefix" {
  description = "Subnet for the frontend VM."
  type        = string
  default     = "10.40.2.0/24"
}

variable "backend_subnet_prefix" {
  description = "Subnet for the backend VM."
  type        = string
  default     = "10.40.3.0/24"
}

variable "private_endpoint_subnet_prefix" {
  description = "Subnet for private endpoints."
  type        = string
  default     = "10.40.4.0/24"
}

variable "ops_subnet_prefix" {
  description = "Subnet reserved for SonarQube, jump hosts, or later operations."
  type        = string
  default     = "10.40.5.0/24"
}

variable "vm_admin_username" {
  description = "Admin username for the Linux virtual machines."
  type        = string
}

variable "vm_admin_password" {
  description = "Admin password for the Linux virtual machines."
  type        = string
  sensitive   = true
}

variable "frontend_private_ip" {
  description = "Static private IP address for the frontend VM."
  type        = string
  default     = "10.40.2.4"
}

variable "backend_private_ip" {
  description = "Static private IP address for the backend VM."
  type        = string
  default     = "10.40.3.4"
}

variable "sonarqube_private_ip" {
  description = "Static private IP address for the SonarQube VM."
  type        = string
  default     = "10.40.5.6"
}

variable "frontend_vm_size" {
  description = "Azure VM size for the frontend VM."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "backend_vm_size" {
  description = "Azure VM size for the backend VM."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "sonarqube_vm_size" {
  description = "Azure VM size for the SonarQube VM."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "db_admin_username" {
  description = "Azure SQL admin username."
  type        = string
}

variable "db_admin_password" {
  description = "Azure SQL admin password."
  type        = string
  sensitive   = true
}

variable "frontend_allowed_origin" {
  description = "Public HTTPS hostname exposed by Application Gateway."
  type        = string
}

variable "app_gateway_certificate_secret_id" {
  description = "Versionless Key Vault secret ID for the Application Gateway certificate."
  type        = string
}

variable "existing_key_vault_id" {
  description = "Resource ID of the existing shared Key Vault that stores the App Gateway certificate."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    project     = "devops-project2-g4"
    owner       = "group4c"
    managed_by  = "terraform"
    environment = "dev"
  }
}
