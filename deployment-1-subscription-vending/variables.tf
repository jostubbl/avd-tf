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
  default     = "usgovarizona"

  validation {
    condition     = contains(["usgovvirginia", "usgovtexas", "usgovarizona"], var.platform_location)
    error_message = "platform_location must be an Azure Government region: usgovvirginia, usgovtexas, or usgovarizona."
  }
}

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

variable "environment" {
  description = <<-EOT
    Deployment environment type.  Controls subscription workload classification
    and resource naming throughout this deployment.
      sandbox    – maps to Azure 'DevTest' subscription workload; for non-production
                   development and test use cases.
      production – maps to Azure 'Production' subscription workload; for live
                   mission workloads.
  EOT
  type        = string
  default     = "production"

  validation {
    condition     = contains(["sandbox", "production"], var.environment)
    error_message = "environment must be 'sandbox' or 'production'."
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
  description = "Display name for the new customer workload subscription."
  type        = string
  default     = "avd-workload-prod"
}

# ---------------------------------------------------------------------------
# ALZ Management Group
# ---------------------------------------------------------------------------

variable "management_group_id" {
  description = "The ID (name) of the ALZ workload management group for subscription placement and policy assignments."
  type        = string
}

# ---------------------------------------------------------------------------
# Required Subscription Tags
# These six tags MUST be present on all resources in this subscription.
# ---------------------------------------------------------------------------

variable "tag_agency" {
  description = "Required tag: Federal agency name (e.g. 'DOD', 'DHS', 'VA')."
  type        = string
}

variable "tag_program_office" {
  description = "Required tag: Program office within the agency (e.g. 'OCIO', 'J6')."
  type        = string
}

variable "tag_charge_site" {
  description = "Required tag: Charge site or cost allocation code for billing attribution."
  type        = string
}

variable "tag_project" {
  description = "Required tag: Project name or project code."
  type        = string
}

variable "tag_application_owner" {
  description = "Required tag: Name or email address of the application/system owner."
  type        = string
}

variable "tag_account" {
  description = "Required tag: Account identifier used for billing, access control, or tracking."
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
# Defender for Cloud & File Integrity Monitoring (FIM)
# ---------------------------------------------------------------------------

variable "law_id" {
  description = <<-EOT
    Resource ID of the CENTRALIZED Log Analytics Workspace to which Defender
    for Cloud and File Integrity Monitoring (FIM) data will be sent.
    This workspace is managed by the platform team and shared across all
    workload subscriptions.
    Format:
      /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<name>
  EOT
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.law_id))
    error_message = "law_id must be a valid Log Analytics Workspace resource ID."
  }
}

# ---------------------------------------------------------------------------
# Hub Networking (optional – disabled by default)
# Per spec, Deployment 1 does NOT deploy virtual networks by default.
# Set deploy_hub_networking = true only when this deployment also manages
# the platform hub connectivity layer.
# ---------------------------------------------------------------------------

variable "deploy_hub_networking" {
  description = <<-EOT
    Deploy hub networking infrastructure (VNet, Azure Firewall, subnets, route
    tables) in the platform subscription.  Defaults to false per the requirement
    that Deployment 1 does not deploy Virtual Networks.  Set to true only when
    this deployment also manages the platform hub connectivity layer.
  EOT
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = <<-EOT
    Additional tags to merge with the required subscription tags.
    The six required tags (agency, program-office, charge-site, project,
    application-owner, account) are always applied automatically from their
    dedicated variables.  Use this map to add supplementary tags.
  EOT
  type        = map(string)
  default = {
    workload         = "avd"
    cost_center      = "platform"
    managed_by       = "platform-team"
    compliance_scope = "fedramp-high"
  }
}
