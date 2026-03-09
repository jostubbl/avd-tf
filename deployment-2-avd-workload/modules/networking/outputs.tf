###############################################################################
# modules/networking/outputs.tf
###############################################################################

output "vnet_id" {
  description = "Resource ID of the spoke VNet."
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Name of the spoke VNet."
  value       = azurerm_virtual_network.spoke.name
}

output "session_host_subnet_id" {
  description = "Resource ID of the AVD session host subnet."
  value       = azurerm_subnet.session_hosts.id
}

output "private_endpoint_subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  value       = azurerm_subnet.private_endpoints.id
}

output "session_host_nsg_id" {
  description = "Resource ID of the session host NSG."
  value       = azurerm_network_security_group.session_hosts.id
}

output "storage_file_private_dns_zone_id" {
  description = "Resource ID of the Azure Files private DNS zone."
  value       = azurerm_private_dns_zone.storage_file.id
}

output "storage_file_private_dns_zone_name" {
  description = "Name of the Azure Files private DNS zone."
  value       = azurerm_private_dns_zone.storage_file.name
}
