###############################################################################
# modules/defender/variables.tf – Microsoft Defender for Cloud Plans
###############################################################################

variable "location" {
  description = "Azure Government region used for the NIST 800-53 policy assignment managed identity."
  type        = string
}

variable "law_id" {
  description = <<-EOT
    Resource ID of the CENTRALIZED Log Analytics Workspace to which Defender
    for Cloud and File Integrity Monitoring (FIM) data will be sent.
    Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>
  EOT
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.law_id))
    error_message = "law_id must be a valid Log Analytics Workspace resource ID."
  }
}

variable "tags" {
  description = "Tags applied to all taggable resources in this module."
  type        = map(string)
  default     = {}
}
