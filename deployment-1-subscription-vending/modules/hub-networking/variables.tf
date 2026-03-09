###############################################################################
# modules/hub-networking/variables.tf – D1 Hub Networking
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group for hub connectivity resources."
  type        = string
}

variable "location" {
  description = "Azure Government region for hub networking resources."
  type        = string
}

variable "workload_name" {
  description = "Short name used in resource naming (e.g. 'platform')."
  type        = string
  default     = "platform"
}

# ---------------------------------------------------------------------------
# Hub VNet address space
# ---------------------------------------------------------------------------

variable "hub_vnet_address_space" {
  description = "Address space CIDR for the hub VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "firewall_subnet_cidr" {
  description = "CIDR for AzureFirewallSubnet (must be /26 or larger, name is fixed)."
  type        = string
  default     = "10.0.0.0/26"
}

variable "gateway_subnet_cidr" {
  description = "CIDR for GatewaySubnet (must be /27 or larger, name is fixed)."
  type        = string
  default     = "10.0.1.0/27"
}

variable "bastion_subnet_cidr" {
  description = "CIDR for AzureBastionSubnet (must be /26 or larger, name is fixed)."
  type        = string
  default     = "10.0.2.0/26"
}

variable "identity_subnet_cidr" {
  description = "CIDR for the Identity subnet (used by AADDS or AD DS VMs)."
  type        = string
  default     = "10.0.3.0/24"
}

variable "management_subnet_cidr" {
  description = "CIDR for the Management subnet (jump hosts, monitoring agents)."
  type        = string
  default     = "10.0.4.0/24"
}

# ---------------------------------------------------------------------------
# Azure Firewall
# ---------------------------------------------------------------------------

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier.  Standard or Premium.  Premium provides IDPS/TLS inspection (recommended for IL5)."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be 'Standard' or 'Premium'."
  }
}

variable "firewall_threat_intel_mode" {
  description = "Azure Firewall Threat Intelligence mode: Off, Alert, or Deny."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.firewall_threat_intel_mode)
    error_message = "firewall_threat_intel_mode must be 'Off', 'Alert', or 'Deny'."
  }
}

# ---------------------------------------------------------------------------
# Optional components
# ---------------------------------------------------------------------------

variable "deploy_vpn_gateway" {
  description = "Deploy a VPN Gateway for site-to-site or P2S connectivity."
  type        = bool
  default     = false
}

variable "vpn_gateway_sku" {
  description = "VPN Gateway SKU.  Used only when deploy_vpn_gateway = true."
  type        = string
  default     = "VpnGw1"
}

variable "deploy_bastion" {
  description = "Deploy Azure Bastion for secure jump-host access to hub resources."
  type        = bool
  default     = false
}

variable "bastion_sku" {
  description = "Azure Bastion SKU (Basic or Standard).  Used only when deploy_bastion = true."
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags applied to all hub networking resources."
  type        = map(string)
  default     = {}
}
