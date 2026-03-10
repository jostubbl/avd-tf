###############################################################################
# modules/networking/outputs.tf – JUCE Networking Module
###############################################################################

output "vnet_id" {
  description = "Resource ID of the JUCE spoke VNet."
  value       = azurerm_virtual_network.juce.id
}

output "vnet_name" {
  description = "Name of the JUCE spoke VNet."
  value       = azurerm_virtual_network.juce.name
}

output "vm_subnet_id" {
  description = "Resource ID of the JUCE VM subnet."
  value       = azurerm_subnet.vm.id
}

output "vm_subnet_name" {
  description = "Name of the JUCE VM subnet."
  value       = azurerm_subnet.vm.name
}

output "private_endpoint_subnet_id" {
  description = "Resource ID of the JUCE private endpoint subnet."
  value       = azurerm_subnet.private_endpoints.id
}

output "nsg_id" {
  description = "Resource ID of the NSG associated with the VM subnet."
  value       = azurerm_network_security_group.vm.id
}

output "nsg_name" {
  description = "Name of the NSG associated with the VM subnet."
  value       = azurerm_network_security_group.vm.name
}
