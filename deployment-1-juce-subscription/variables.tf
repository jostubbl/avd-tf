###############################################################################
# variables.tf – Deployment 1: JUCE Subscription + Baseline Configuration
###############################################################################

# ---------------------------------------------------------------------------
# Subscription identity
# ---------------------------------------------------------------------------

variable "subscription_name" {
  description = "Display name for the JUCE workload subscription."
  type        = string
}

variable "workload_subscription_id" {
  description = <<-EOT
    The UUID of the JUCE workload subscription to configure.

    Two-phase deployment for NEW subscriptions:
      Phase 1 – Leave empty when billing_scope_id is set to create the subscription.
                 Defender, FIM, and NIST policy resources are skipped automatically.
                 After apply, retrieve the subscription_id from Terraform output.
      Phase 2 – Set this to the subscription_id output from Phase 1.
                 All Defender, FIM, and NIST policy resources are then applied.

    For EXISTING subscriptions, always provide this value.
  EOT
  type        = string
  default     = ""
}

variable "billing_scope_id" {
  description = <<-EOT
    (Optional) The fully-qualified Azure billing scope under which to create a
    new JUCE workload subscription.  Example (EA Enrollment Account):
      /providers/Microsoft.Billing/billingAccounts/<BA_ID>/enrollmentAccounts/<EA_ID>
    Leave empty if the subscription already exists.
  EOT
  type        = string
  default     = ""
}

variable "management_group_id" {
  description = <<-EOT
    (Optional) The ID (name) of the ALZ management group under which the
    subscription should be placed.  Leave empty to skip MG association.
  EOT
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Deployment environment.  Allowed values: sandbox, production."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["sandbox", "production"], var.environment)
    error_message = "environment must be 'sandbox' or 'production'."
  }
}

# ---------------------------------------------------------------------------
# Region
# ---------------------------------------------------------------------------

variable "location" {
  description = "Azure Government region for all JUCE resources.  Must be usgovarizona."
  type        = string
  default     = "usgovarizona"

  validation {
    condition     = var.location == "usgovarizona"
    error_message = "All JUCE deployments must target usgovarizona."
  }
}

# ---------------------------------------------------------------------------
# File Integrity Monitoring – centralized Log Analytics Workspace
# ---------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = <<-EOT
    Resource ID of the CENTRALIZED Log Analytics Workspace to which Defender
    for Cloud (including File Integrity Monitoring) will send security data.
    Example:
      /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>
  EOT
  type        = string
}

# ---------------------------------------------------------------------------
# Required subscription tags
# ---------------------------------------------------------------------------

variable "tag_agency" {
  description = "Tag: agency — the government agency that owns this subscription."
  type        = string
}

variable "tag_program_office" {
  description = "Tag: program-office — the program office responsible for this subscription."
  type        = string
}

variable "tag_charge_site" {
  description = "Tag: charge-site — the cost center or charge site for billing purposes."
  type        = string
}

variable "tag_project" {
  description = "Tag: project — the project name or identifier associated with this subscription."
  type        = string
}

variable "tag_application_owner" {
  description = "Tag: application-owner — the name or email of the application owner."
  type        = string
}

variable "tag_account" {
  description = "Tag: account — the account identifier (e.g. Azure EA account or cost code)."
  type        = string
}
