output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.app_gateway.ip_address
}

output "application_gateway_url" {
  value = "https://${azurerm_public_ip.app_gateway.ip_address}"
}

output "frontend_vm_private_ip" {
  value = azurerm_network_interface.frontend.private_ip_address
}

output "backend_vm_private_ip" {
  value = azurerm_network_interface.backend.private_ip_address
}

output "sonarqube_vm_private_ip" {
  value = azurerm_network_interface.sonarqube.private_ip_address
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}
