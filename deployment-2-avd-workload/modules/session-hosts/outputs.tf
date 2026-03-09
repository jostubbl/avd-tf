###############################################################################
# modules/session-hosts/outputs.tf
###############################################################################

output "vm_ids" {
  description = "List of resource IDs for the deployed session host VMs."
  value       = azurerm_windows_virtual_machine.session_host[*].id
}

output "vm_names" {
  description = "List of names for the deployed session host VMs."
  value       = azurerm_windows_virtual_machine.session_host[*].name
}

output "availability_set_id" {
  description = "Resource ID of the session host availability set."
  value       = azurerm_availability_set.session_hosts.id
}

output "vm_principal_ids" {
  description = "List of system-assigned managed identity principal IDs for session host VMs."
  value       = azurerm_windows_virtual_machine.session_host[*].identity[0].principal_id
}
