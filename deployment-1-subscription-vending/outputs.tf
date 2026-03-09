###############################################################################
# outputs.tf – Deployment 1: Platform / Subscription Vending
#
# These outputs are consumed by Deployment 2 (AVD workload) via remote state
# or passed as pipeline variables in GitLab CI/CD.
###############################################################################

output "subscription_id" {
  description = "The UUID of the newly vended AVD workload subscription."
  value       = azurerm_subscription.avd_workload.subscription_id
  sensitive   = false
}

output "subscription_resource_id" {
  description = "The full ARM resource ID of the vended subscription (e.g. /subscriptions/<UUID>)."
  value       = azurerm_subscription.avd_workload.id
  sensitive   = false
}

output "tenant_id" {
  description = "The Azure AD tenant ID associated with the subscription."
  value       = azurerm_subscription.avd_workload.tenant_id
  sensitive   = false
}

output "management_group_id" {
  description = "The ID of the ALZ management group the subscription was placed into."
  value       = var.management_group_id
  sensitive   = false
}

output "subscription_name" {
  description = "Display name of the vended subscription."
  value       = azurerm_subscription.avd_workload.subscription_name
  sensitive   = false
}

output "monthly_budget_id" {
  description = "Resource ID of the monthly consumption budget."
  value       = azurerm_consumption_budget_subscription.monthly.id
  sensitive   = false
}
