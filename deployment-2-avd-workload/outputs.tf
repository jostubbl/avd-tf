###############################################################################
# outputs.tf – Deployment 2: Customer AVD Workload Landing Zone
###############################################################################

output "resource_group_networking" {
  description = "Name of the networking resource group."
  value       = azurerm_resource_group.networking.name
}

output "resource_group_compute" {
  description = "Name of the compute (session hosts) resource group."
  value       = azurerm_resource_group.compute.name
}

output "resource_group_storage" {
  description = "Name of the profile storage resource group."
  value       = azurerm_resource_group.storage.name
}

output "resource_group_avd" {
  description = "Name of the AVD management plane resource group."
  value       = azurerm_resource_group.avd.name
}

output "spoke_vnet_id" {
  description = "Resource ID of the customer spoke VNet."
  value       = module.networking.vnet_id
}

output "spoke_vnet_name" {
  description = "Name of the customer spoke VNet."
  value       = module.networking.vnet_name
}

output "session_host_subnet_id" {
  description = "Resource ID of the AVD session host subnet."
  value       = module.networking.session_host_subnet_id
}

output "host_pool_id" {
  description = "Resource ID of the AVD host pool."
  value       = module.avd.host_pool_id
}

output "host_pool_name" {
  description = "Name of the AVD host pool."
  value       = module.avd.host_pool_name
}

output "workspace_id" {
  description = "Resource ID of the AVD workspace."
  value       = module.avd.workspace_id
}

output "application_group_id" {
  description = "Resource ID of the AVD desktop application group."
  value       = module.avd.application_group_id
}

output "storage_account_name" {
  description = "Name of the FSLogix profile storage account."
  value       = module.profile_storage.storage_account_name
}

output "fslogix_share_name" {
  description = "Name of the FSLogix Azure Files share."
  value       = module.profile_storage.fslogix_share_name
}

output "session_host_vm_ids" {
  description = "List of resource IDs for the deployed session host VMs."
  value       = module.session_hosts.vm_ids
}

output "msix_storage_account_name" {
  description = "Name of the MSIX App Attach storage account."
  value       = module.msix_storage.storage_account_name
}

output "msix_share_name" {
  description = "Name of the MSIX packages Azure Files share."
  value       = module.msix_storage.msix_share_name
}

output "msix_share_url" {
  description = "UNC path for the MSIX share (Azure Government endpoint)."
  value       = module.msix_storage.msix_share_url
}
