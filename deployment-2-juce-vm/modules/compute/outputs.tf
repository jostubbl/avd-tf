###############################################################################
# modules/compute/outputs.tf – JUCE Compute Module
###############################################################################

output "vm_ids" {
  description = "List of resource IDs for all deployed JUCE virtual machines."
  value       = azurerm_windows_virtual_machine.juce[*].id
}

output "vm_names" {
  description = "List of names for all deployed JUCE virtual machines."
  value       = azurerm_windows_virtual_machine.juce[*].name
}

output "vm_principal_ids" {
  description = "List of system-assigned managed identity principal IDs for all JUCE VMs."
  value       = azurerm_windows_virtual_machine.juce[*].identity[0].principal_id
}

output "nic_ids" {
  description = "List of resource IDs for all JUCE VM network interface cards."
  value       = azurerm_network_interface.juce[*].id
}

output "availability_set_id" {
  description = "Resource ID of the availability set (null when availability zones are used instead)."
  value       = length(var.availability_zone) == 0 ? azurerm_availability_set.juce[0].id : null
}
