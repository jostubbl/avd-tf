###############################################################################
# modules/defender/outputs.tf – Microsoft Defender for Cloud Plans
###############################################################################

output "nist_800_53_r5_subscription_assignment_id" {
  description = "Resource ID of the NIST SP 800-53 Rev. 5 policy assignment at subscription scope."
  value       = azurerm_subscription_policy_assignment.nist_800_53_r5.id
}

output "fim_workspace_id" {
  description = "The Log Analytics Workspace ID configured for FIM / Defender for Cloud data collection."
  value       = azurerm_security_center_workspace.fim.workspace_id
}
