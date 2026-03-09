###############################################################################
# variables.tf – Deployment 1: Platform / Subscription Vending
###############################################################################

# ---------------------------------------------------------------------------
# Provider / platform context
# ---------------------------------------------------------------------------

variable "platform_subscription_id" {
  description = "The subscription ID of the platform/management subscription used to authenticate the Terraform provider."
  type        = string
}

# ---------------------------------------------------------------------------
# Subscription creation (EA / MCA billing scope)
# ---------------------------------------------------------------------------

variable "billing_scope_id" {
  description = <<-EOT
    The fully-qualified Azure billing scope under which the new subscription
    will be created.  This is typically an Enrollment Account resource ID, e.g.:
      /providers/Microsoft.Billing/billingAccounts/<BA_ID>/enrollmentAccounts/<EA_ID>
    For MCA the format differs; see azurerm_subscription docs.
  EOT
  type        = string
}

variable "subscription_name" {
  description = "Display name for the new customer AVD workload subscription."
  type        = string
  default     = "avd-workload-prod"
}

variable "subscription_workload" {
  description = "Type of workload for the subscription. Allowed: Production, DevTest."
  type        = string
  default     = "Production"

  validation {
    condition     = contains(["Production", "DevTest"], var.subscription_workload)
    error_message = "subscription_workload must be 'Production' or 'DevTest'."
  }
}

# ---------------------------------------------------------------------------
# ALZ Management Group placement
# ---------------------------------------------------------------------------

variable "management_group_id" {
  description = <<-EOT
    The ID (name/display-path) of the ALZ workload management group under which
    the vended subscription will be placed.  Example: 'alz-landingzones-corp'.
  EOT
  type        = string
}

# ---------------------------------------------------------------------------
# RBAC – Role Assignments
# ---------------------------------------------------------------------------

variable "technical_owner_object_ids" {
  description = "List of Azure AD object IDs for customer technical owners (Owner role at subscription scope)."
  type        = list(string)
  default     = []
}

variable "finance_ops_object_ids" {
  description = "List of Azure AD object IDs for customer finance/ops users (Cost Management Reader role)."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Budget & Alerts
# ---------------------------------------------------------------------------

variable "budget_name" {
  description = "Name of the monthly consumption budget."
  type        = string
  default     = "avd-workload-monthly-budget"
}

variable "budget_amount_usd" {
  description = "Monthly budget amount in USD."
  type        = number
  default     = 5000
}

variable "budget_alert_emails" {
  description = "List of e-mail addresses that receive budget alert notifications."
  type        = list(string)
  default     = []
}

variable "budget_start_date" {
  description = <<-EOT
    Start date for the budget in RFC3339 format (first day of a month).
    Example: '2025-01-01T00:00:00Z'
  EOT
  type        = string
}

variable "budget_end_date" {
  description = "End date for the budget in RFC3339 format."
  type        = string
  default     = "2030-12-01T00:00:00Z"
}

# ---------------------------------------------------------------------------
# Tags – applied to the subscription and all platform-managed resources
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Map of tags to apply to all resources in this deployment."
  type        = map(string)
  default = {
    environment      = "production"
    workload         = "avd"
    cost_center      = "customer"
    managed_by       = "platform-team"
    compliance_scope = "fedramp-high"
  }
}
