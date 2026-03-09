###############################################################################
# variables.tf – Deployment 1: Platform / Subscription Vending
###############################################################################

# ---------------------------------------------------------------------------
# Provider / platform context
# ---------------------------------------------------------------------------

variable "platform_subscription_id" {
  description = "The subscription ID of the platform/management subscription used to authenticate the Terraform provider and to deploy hub networking and identity resources."
  type        = string
}

variable "platform_location" {
  description = "Primary Azure Government region for platform (hub, identity) resources."
  type        = string
  default     = "usgovvirginia"

  validation {
    condition     = contains(["usgovvirginia", "usgovtexas", "usgovarizona"], var.platform_location)
    error_message = "platform_location must be an Azure Government region: usgovvirginia, usgovtexas, or usgovarizona."
  }
}

# ---------------------------------------------------------------------------
# Subscription creation (EA / MCA billing scope)
# ---------------------------------------------------------------------------

variable "billing_scope_id" {
  description = <<-EOT
    The fully-qualified Azure billing scope under which the new subscription
    will be created.  This is typically an Enrollment Account resource ID, e.g.:
      /providers/Microsoft.Billing/billingAccounts/<BA_ID>/enrollmentAccounts/<EA_ID>
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
# ALZ Management Group
# ---------------------------------------------------------------------------

variable "management_group_id" {
  description = "The ID (name) of the ALZ workload management group for subscription placement and policy assignments."
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
  description = "Start date for the budget in RFC3339 format (first day of a month), e.g. '2025-01-01T00:00:00Z'."
  type        = string
}

variable "budget_end_date" {
  description = "End date for the budget in RFC3339 format."
  type        = string
  default     = "2030-12-01T00:00:00Z"
}

# ---------------------------------------------------------------------------
# Hub Networking
# ---------------------------------------------------------------------------

variable "hub_vnet_address_space" {
  description = "Address space CIDR(s) for the hub VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "firewall_subnet_cidr" {
  description = "CIDR for AzureFirewallSubnet (min /26, required name)."
  type        = string
  default     = "10.0.0.0/26"
}

variable "gateway_subnet_cidr" {
  description = "CIDR for GatewaySubnet (min /27, required name)."
  type        = string
  default     = "10.0.1.0/27"
}

variable "bastion_subnet_cidr" {
  description = "CIDR for AzureBastionSubnet (min /26, required name)."
  type        = string
  default     = "10.0.2.0/26"
}

variable "identity_subnet_cidr" {
  description = "CIDR for the Identity subnet (used by AADDS)."
  type        = string
  default     = "10.0.3.0/24"
}

variable "management_subnet_cidr" {
  description = "CIDR for the Management subnet."
  type        = string
  default     = "10.0.4.0/24"
}

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier: Standard or Premium."
  type        = string
  default     = "Standard"
}

variable "firewall_threat_intel_mode" {
  description = "Azure Firewall Threat Intelligence mode: Off, Alert, or Deny."
  type        = string
  default     = "Deny"
}

variable "deploy_vpn_gateway" {
  description = "Deploy a VPN Gateway for site-to-site connectivity."
  type        = bool
  default     = false
}

variable "vpn_gateway_sku" {
  description = "VPN Gateway SKU (only used when deploy_vpn_gateway = true)."
  type        = string
  default     = "VpnGw1"
}

variable "deploy_bastion" {
  description = "Deploy Azure Bastion for secure jump-host access."
  type        = bool
  default     = false
}

variable "bastion_sku" {
  description = "Azure Bastion SKU: Basic or Standard."
  type        = string
  default     = "Standard"
}

# ---------------------------------------------------------------------------
# Identity (Azure AD Domain Services)
# ---------------------------------------------------------------------------

variable "deploy_aadds" {
  description = <<-EOT
    Deploy Azure AD Domain Services.
    Requires Azure AD Premium P1/P2 licenses in the tenant.
    Set to false to skip AADDS; manage identity externally.
  EOT
  type        = bool
  default     = false
}

variable "aadds_domain_name" {
  description = "FQDN for the AADDS managed domain (e.g. 'aadds.contoso.gov').  Required when deploy_aadds = true."
  type        = string
  default     = ""
}

variable "aadds_sku" {
  description = "AADDS SKU: Standard, Enterprise, or Premium."
  type        = string
  default     = "Standard"
}

variable "aadds_notification_emails" {
  description = "Additional e-mail addresses for AADDS health notifications."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Policy Assignments
# ---------------------------------------------------------------------------

variable "assign_fedramp_high" {
  description = "Assign the FedRAMP High built-in initiative at management group scope."
  type        = bool
  default     = true
}

variable "assign_nist_800_53_r5" {
  description = "Assign the NIST SP 800-53 Rev 5 built-in initiative at management group scope."
  type        = bool
  default     = true
}

variable "assign_azure_security_benchmark" {
  description = "Assign the Microsoft Cloud Security Benchmark initiative at management group scope."
  type        = bool
  default     = true
}

variable "policy_enforcement_mode" {
  description = "Policy enforcement mode: 'Default' (enforced) or 'DoNotEnforce' (audit-only)."
  type        = string
  default     = "Default"
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Map of tags to apply to all resources in this deployment."
  type        = map(string)
  default = {
    environment      = "production"
    workload         = "avd"
    cost_center      = "platform"
    managed_by       = "platform-team"
    compliance_scope = "fedramp-high"
  }
}
