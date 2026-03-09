###############################################################################
# modules/hub-networking/outputs.tf
###############################################################################

output "hub_vnet_id" {
  description = "Resource ID of the hub VNet."
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub VNet."
  value       = azurerm_virtual_network.hub.name
}

output "identity_subnet_id" {
  description = "Resource ID of the Identity subnet (used by AADDS or AD DS VMs)."
  value       = azurerm_subnet.identity.id
}

output "management_subnet_id" {
  description = "Resource ID of the Management subnet."
  value       = azurerm_subnet.management.id
}

output "gateway_subnet_id" {
  description = "Resource ID of the GatewaySubnet."
  value       = azurerm_subnet.gateway.id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall (used as next-hop in spoke route tables)."
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_id" {
  description = "Resource ID of the Azure Firewall."
  value       = azurerm_firewall.hub.id
}

output "firewall_policy_id" {
  description = "Resource ID of the Azure Firewall Policy."
  value       = azurerm_firewall_policy.hub.id
}

output "spoke_route_table_id" {
  description = "Resource ID of the default spoke route table (routes traffic through the hub firewall)."
  value       = azurerm_route_table.spoke_default.id
}

output "vpn_gateway_id" {
  description = "Resource ID of the VPN Gateway (empty string if not deployed)."
  value       = var.deploy_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : ""
}

output "vpn_gateway_public_ip" {
  description = "Public IP address of the VPN Gateway (empty string if not deployed)."
  value       = var.deploy_vpn_gateway ? azurerm_public_ip.vpn_gateway[0].ip_address : ""
}
