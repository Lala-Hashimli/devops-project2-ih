data "azurerm_client_config" "current" {}

locals {
  prefix = "devops-p2"

  resource_group_name = "rg-${local.prefix}-${var.name_suffix}"
  vnet_name           = "vnet-${local.prefix}-${var.name_suffix}"

  appgw_subnet_name    = "snet-appgw-${var.name_suffix}"
  frontend_subnet_name = "snet-frontend-${var.name_suffix}"
  backend_subnet_name  = "snet-backend-${var.name_suffix}"
  pe_subnet_name       = "snet-pe-${var.name_suffix}"
  ops_subnet_name      = "snet-ops-${var.name_suffix}"

  law_name               = "law-${local.prefix}-${var.name_suffix}"
  appi_name              = "appi-${local.prefix}-${var.name_suffix}"
  sql_server_name        = "sqlsrv${replace(local.prefix, "-", "")}${var.name_suffix}"
  sql_database_name      = "sqldb-burger-${var.name_suffix}"
  gateway_name           = "agw-${local.prefix}-${var.name_suffix}"
  gateway_public_ip_name = "pip-agw-${var.name_suffix}"
  gateway_identity_name  = "uai-agw-${var.name_suffix}"

  frontend_vm_name  = "vm-frontend-${var.name_suffix}"
  backend_vm_name   = "vm-backend-${var.name_suffix}"
  sonarqube_vm_name = "vm-sonarqube-${var.name_suffix}"
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.common_tags
}

resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.address_space]
  tags                = var.common_tags
}

resource "azurerm_subnet" "appgw" {
  name                 = local.appgw_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.appgw_subnet_prefix]
}

resource "azurerm_subnet" "frontend" {
  name                 = local.frontend_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.frontend_subnet_prefix]
}

resource "azurerm_subnet" "backend" {
  name                 = local.backend_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.backend_subnet_prefix]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = local.pe_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_endpoint_subnet_prefix]
}

resource "azurerm_subnet" "ops" {
  name                 = local.ops_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.ops_subnet_prefix]
}

resource "azurerm_network_security_group" "frontend" {
  name                = "nsg-frontend-${var.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  security_rule {
    name                       = "allow-http-from-appgw"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.appgw_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-from-ops"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ops_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend" {
  name                = "nsg-backend-${var.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  security_rule {
    name                       = "allow-api-from-appgw"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.appgw_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh-from-ops"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ops_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}

resource "azurerm_network_security_group" "ops" {
  name                = "nsg-ops-${var.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  security_rule {
    name                       = "allow-ssh-from-ops"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ops_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-sonarqube-web-from-vnet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = var.address_space
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "ops" {
  subnet_id                 = azurerm_subnet.ops.id
  network_security_group_id = azurerm_network_security_group.ops.id
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.law_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.common_tags
}

resource "azurerm_application_insights" "main" {
  name                = local.appi_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.common_tags
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "sql-vnet-link-${var.name_suffix}"
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = var.common_tags
}

resource "azurerm_mssql_server" "main" {
  name                          = local.sql_server_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  version                       = "12.0"
  administrator_login           = var.db_admin_username
  administrator_login_password  = var.db_admin_password
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
  tags                          = var.common_tags
}

resource "azurerm_mssql_database" "main" {
  name           = local.sql_database_name
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "Basic"
  max_size_gb    = 2
  zone_redundant = false
  tags           = var.common_tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${var.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.common_tags

  private_service_connection {
    name                           = "psc-sql-${var.name_suffix}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

resource "azurerm_network_interface" "frontend" {
  name                = "nic-frontend-${var.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "frontend-ipconfig"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.frontend_private_ip
  }
}

resource "azurerm_network_interface" "backend" {
  name                = "nic-backend-${var.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "backend-ipconfig"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.backend_private_ip
  }
}

resource "azurerm_network_interface" "sonarqube" {
  name                = "nic-sonarqube-${var.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "sonarqube-ipconfig"
    subnet_id                     = azurerm_subnet.ops.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.sonarqube_private_ip
  }
}

resource "azurerm_linux_virtual_machine" "frontend" {
  name                = local.frontend_vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.frontend_vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.frontend.id,
  ]
  disable_password_authentication = false
  tags                            = var.common_tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "backend" {
  name                = local.backend_vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.backend_vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.backend.id,
  ]
  disable_password_authentication = false
  tags                            = var.common_tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "sonarqube" {
  name                = local.sonarqube_vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.sonarqube_vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.sonarqube.id,
  ]
  disable_password_authentication = false
  tags                            = var.common_tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_user_assigned_identity" "app_gateway" {
  name                = local.gateway_identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags
}

resource "azurerm_role_assignment" "app_gateway_kv_secrets_user" {
  scope                = var.existing_key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_gateway.principal_id
}

resource "azurerm_public_ip" "app_gateway" {
  name                = local.gateway_public_ip_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

resource "azurerm_web_application_firewall_policy" "app_gateway" {
  name                = "wafp-${local.prefix}-${var.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "main" {
  name                = local.gateway_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.common_tags

  depends_on = [azurerm_role_assignment.app_gateway_kv_secrets_user]

  firewall_policy_id = azurerm_web_application_firewall_policy.app_gateway.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway.id]
  }

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 3
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  frontend_port {
    name = "https-443"
    port = 443
  }

  ssl_certificate {
    name                = "appgw-shared-cert"
    key_vault_secret_id = var.app_gateway_certificate_secret_id
  }

  backend_address_pool {
    name         = "frontend-pool"
    ip_addresses = [var.frontend_private_ip]
  }

  backend_address_pool {
    name         = "backend-pool"
    ip_addresses = [var.backend_private_ip]
  }

  probe {
    name                = "frontend-probe"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = "127.0.0.1"

    match {
      status_code = ["200-399"]
    }
  }

  probe {
    name                = "backend-probe"
    protocol            = "Http"
    path                = "/api/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = "127.0.0.1"

    match {
      status_code = ["200-399"]
    }
  }

  backend_http_settings {
    name                  = "frontend-http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "frontend-probe"
  }

  backend_http_settings {
    name                  = "backend-http"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "backend-probe"
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "https-443"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-shared-cert"
  }

  url_path_map {
    name                               = "project2-path-map"
    default_backend_address_pool_name  = "frontend-pool"
    default_backend_http_settings_name = "frontend-http"

    path_rule {
      name                       = "backend-api-rule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "backend-pool"
      backend_http_settings_name = "backend-http"
    }
  }

  request_routing_rule {
    name               = "https-path-routing"
    rule_type          = "PathBasedRouting"
    http_listener_name = "https-listener"
    url_path_map_name  = "project2-path-map"
    priority           = 100
  }

}

resource "azurerm_monitor_action_group" "main" {
  name                = "ag-monitor-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "grp4cmon"
  tags                = var.common_tags
}

resource "azurerm_monitor_metric_alert" "app_gateway_unhealthy" {
  name                = "alert-appgw-unhealthy-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_gateway.main.id]
  description         = "Alert when Application Gateway sees unhealthy backend hosts."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }
}

resource "azurerm_monitor_metric_alert" "frontend_cpu" {
  name                = "alert-frontend-cpu-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.frontend.id]
  description         = "Alert when frontend VM CPU stays high for five minutes."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }
}

resource "azurerm_monitor_metric_alert" "sql_cpu" {
  name                = "alert-sql-cpu-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_mssql_database.main.id]
  description         = "Alert when Azure SQL CPU percent stays high for five minutes."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}
