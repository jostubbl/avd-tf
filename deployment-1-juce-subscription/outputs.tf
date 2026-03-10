###############################################################################
# outputs.tf – Deployment 1: JUCE Subscription + Baseline Configuration
###############################################################################

output "subscription_id" {
  description = "The UUID of the JUCE workload subscription.  Use as workload_subscription_id input for Deployment 2."
  value       = azurerm_subscription.juce.subscription_id
}

output "subscription_resource_id" {
  description = "The full Azure resource ID of the JUCE workload subscription."
  value       = azurerm_subscription.juce.id
}

output "tenant_id" {
  description = "The Azure AD tenant ID associated with the JUCE workload subscription."
  value       = azurerm_subscription.juce.tenant_id
}

output "subscription_name" {
  description = "The display name of the JUCE workload subscription."
  value       = azurerm_subscription.juce.subscription_name
}

output "nist_policy_assignment_id" {
  description = "Resource ID of the NIST SP 800-53 Rev. 5 policy assignment applied to the subscription.  Empty string during Phase 1 (before workload_subscription_id is set)."
  value       = local.configure_subscription ? azurerm_subscription_policy_assignment.nist_800_53_r5[0].id : ""
}

output "security_center_workspace_id" {
  description = "The centralized Log Analytics Workspace ID configured for Defender for Cloud / FIM.  Empty string during Phase 1."
  value       = local.configure_subscription ? azurerm_security_center_workspace.fim[0].workspace_id : ""
}
