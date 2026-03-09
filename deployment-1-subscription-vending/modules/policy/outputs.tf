###############################################################################
# modules/policy/outputs.tf
###############################################################################

output "fedramp_high_assignment_id" {
  description = "Resource ID of the FedRAMP High policy assignment (empty string if not assigned)."
  value       = var.assign_fedramp_high ? azurerm_management_group_policy_assignment.fedramp_high[0].id : ""
}

output "nist_800_53_r5_assignment_id" {
  description = "Resource ID of the NIST SP 800-53 Rev 5 policy assignment (empty string if not assigned)."
  value       = var.assign_nist_800_53_r5 ? azurerm_management_group_policy_assignment.nist_800_53_r5[0].id : ""
}

output "mcsb_assignment_id" {
  description = "Resource ID of the Microsoft Cloud Security Benchmark assignment (empty string if not assigned)."
  value       = var.assign_azure_security_benchmark ? azurerm_management_group_policy_assignment.mcsb[0].id : ""
}
