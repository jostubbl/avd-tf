###############################################################################
# modules/avd/outputs.tf
###############################################################################

output "host_pool_id" {
  description = "Resource ID of the AVD host pool."
  value       = module.host_pool.resource_id
}

output "host_pool_name" {
  description = "Name of the AVD host pool."
  value       = var.host_pool_name
}

output "host_pool_registration_token" {
  description = "Current registration token for joining session hosts to the host pool."
  value       = module.host_pool.registrationinfo_token
  sensitive   = true
}

output "application_group_id" {
  description = "Resource ID of the AVD desktop application group."
  value       = module.application_group.resource_id
}

output "workspace_id" {
  description = "Resource ID of the AVD workspace."
  value       = module.workspace.resource_id
}

output "workspace_name" {
  description = "Name of the AVD workspace."
  value       = var.workspace_name
}
