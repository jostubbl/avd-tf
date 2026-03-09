###############################################################################
# modules/policy/variables.tf – D1 Management Group Policy Assignments
###############################################################################

variable "management_group_id" {
  description = "The ID (name) of the ALZ management group at which to assign policies."
  type        = string
}

variable "location" {
  description = "Azure Government region used for policy assignment managed identities."
  type        = string
}

variable "assign_fedramp_high" {
  description = "Assign the built-in FedRAMP High initiative at management group scope."
  type        = bool
  default     = true
}

variable "assign_nist_800_53_r5" {
  description = "Assign the built-in NIST SP 800-53 Rev 5 initiative at management group scope."
  type        = bool
  default     = true
}

variable "assign_azure_security_benchmark" {
  description = "Assign the Microsoft Cloud Security Benchmark initiative at management group scope."
  type        = bool
  default     = true
}

variable "policy_enforcement_mode" {
  description = <<-EOT
    Enforcement mode for all policy assignments.
    'Default' – policies are enforced and non-compliant resources are flagged.
    'DoNotEnforce' – audit-only mode; useful during initial rollout.
  EOT
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "DoNotEnforce"], var.policy_enforcement_mode)
    error_message = "policy_enforcement_mode must be 'Default' or 'DoNotEnforce'."
  }
}

variable "tags" {
  description = "Tags applied to all policy assignment resources."
  type        = map(string)
  default     = {}
}
