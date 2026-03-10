###############################################################################
# outputs.tf – Deployment 2: JUCE Customer VM Workload
###############################################################################

# ---------------------------------------------------------------------------
# Resource Groups
# ---------------------------------------------------------------------------

output "networking_resource_group_name" {
  description = "Name of the JUCE networking resource group."
  value       = azurerm_resource_group.networking.name
}

output "compute_resource_group_name" {
  description = "Name of the JUCE compute resource group."
  value       = azurerm_resource_group.compute.name
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

output "vnet_id" {
  description = "Resource ID of the JUCE spoke VNet."
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the JUCE spoke VNet."
  value       = module.networking.vnet_name
}

output "vm_subnet_id" {
  description = "Resource ID of the JUCE VM subnet."
  value       = module.networking.vm_subnet_id
}

output "nsg_id" {
  description = "Resource ID of the JUCE VM subnet NSG."
  value       = module.networking.nsg_id
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------

output "vm_ids" {
  description = "List of resource IDs for all deployed JUCE virtual machines."
  value       = module.compute.vm_ids
}

output "vm_names" {
  description = "List of names for all deployed JUCE virtual machines."
  value       = module.compute.vm_names
}

output "availability_set_id" {
  description = "Resource ID of the JUCE availability set (populated only when availability_zone is empty)."
  value       = module.compute.availability_set_id
}
