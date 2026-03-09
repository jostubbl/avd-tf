###############################################################################
# variables.tf – Deployment 2: Customer AVD Workload Landing Zone
###############################################################################

# ---------------------------------------------------------------------------
# Subscription (from Deployment 1 outputs)
# ---------------------------------------------------------------------------

variable "avd_subscription_id" {
  description = "The UUID of the customer AVD workload subscription (output of Deployment 1)."
  type        = string
}

# ---------------------------------------------------------------------------
# Location & naming
# ---------------------------------------------------------------------------

variable "location" {
  description = <<-EOT
    Primary Azure Government region for all customer resources.
    Must be an Azure Government–available region.
    Recommended: usgovvirginia (US Gov Virginia).
  EOT
  type        = string
  default     = "usgovvirginia"

  validation {
    condition     = contains(["usgovvirginia", "usgovtexas", "usgovarizona"], var.location)
    error_message = "location must be an Azure Government region: usgovvirginia, usgovtexas, or usgovarizona."
  }
}

variable "environment" {
  description = "Short environment name used in resource naming (e.g. prod, dev, uat)."
  type        = string
  default     = "prod"
}

variable "workload_name" {
  description = "Short workload name used in resource naming (e.g. avd)."
  type        = string
  default     = "avd"
}

# ---------------------------------------------------------------------------
# Networking – Spoke VNet
# ---------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space CIDR(s) for the customer spoke VNet."
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "session_host_subnet_cidr" {
  description = "CIDR for the AVD session host subnet."
  type        = string
  default     = "10.100.1.0/24"
}

variable "private_endpoint_subnet_cidr" {
  description = "CIDR for the private endpoint subnet (FSLogix storage, Key Vault, etc.)."
  type        = string
  default     = "10.100.2.0/24"
}

variable "hub_vnet_id" {
  description = <<-EOT
    Resource ID of the central hub VNet (platform-owned) to peer with.
    Supplied by the platform team.  Leave empty to skip peering.
  EOT
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "Custom DNS server IPs for the spoke VNet (e.g. hub DNS forwarders)."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Session Hosts
# ---------------------------------------------------------------------------

variable "session_host_count" {
  description = "Number of AVD session host VMs to deploy."
  type        = number
  default     = 2

  validation {
    condition     = var.session_host_count >= 1 && var.session_host_count <= 50
    error_message = "session_host_count must be between 1 and 50."
  }
}

variable "session_host_vm_size" {
  description = "VM SKU for AVD session hosts.  Must be available in Azure Government."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "session_host_os_disk_type" {
  description = "OS disk storage type for session hosts.  Premium_LRS recommended for performance."
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Premium_LRS", "StandardSSD_LRS", "Standard_LRS"], var.session_host_os_disk_type)
    error_message = "session_host_os_disk_type must be Premium_LRS, StandardSSD_LRS, or Standard_LRS."
  }
}

variable "session_host_image" {
  description = "Marketplace image reference for session host VMs."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-24h2-avd"
    version   = "latest"
  }
}

variable "local_admin_username" {
  description = "Local administrator username for session host VMs."
  type        = string
  default     = "avdadmin"
}

variable "local_admin_password" {
  description = "Local administrator password for session host VMs.  Supplied via CI/CD secret."
  type        = string
  sensitive   = true
}

variable "domain_join_type" {
  description = <<-EOT
    How session hosts join a directory.
    'AAD'  – Azure Active Directory / Entra ID join (no on-prem AD required).
    'ADDS' – Traditional Active Directory Domain Services join.
  EOT
  type        = string
  default     = "AAD"

  validation {
    condition     = contains(["AAD", "ADDS"], var.domain_join_type)
    error_message = "domain_join_type must be 'AAD' or 'ADDS'."
  }
}

variable "domain_name" {
  description = "FQDN of the AD domain (only required when domain_join_type = 'ADDS')."
  type        = string
  default     = ""
}

variable "domain_join_username" {
  description = "UPN of the domain-join service account (only required when domain_join_type = 'ADDS')."
  type        = string
  default     = ""
}

variable "domain_join_password" {
  description = "Password of the domain-join service account (only required when domain_join_type = 'ADDS')."
  type        = string
  sensitive   = true
  default     = ""
}

variable "domain_ou_path" {
  description = "OU path for the computer accounts (only required when domain_join_type = 'ADDS')."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Profile Storage (FSLogix)
# Customer Cost: Storage account charges (capacity + transactions) are
# entirely customer-billable.
# ---------------------------------------------------------------------------

variable "fslogix_share_size_gb" {
  description = "Quota in GB for the FSLogix Azure Files share."
  type        = number
  default     = 1024
}

variable "storage_account_replication" {
  description = "Replication type for the FSLogix storage account.  ZRS recommended for production."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS"], var.storage_account_replication)
    error_message = "storage_account_replication must be LRS, ZRS, GRS, or GZRS."
  }
}

# ---------------------------------------------------------------------------
# AVD Management Plane
# Customer Cost: Host pools, application groups, and workspaces have no
# direct Azure compute cost, but the session VMs they control are billable.
# ---------------------------------------------------------------------------

variable "avd_host_pool_name" {
  description = "Name of the AVD host pool."
  type        = string
  default     = "hp-avd-prod"
}

variable "avd_host_pool_type" {
  description = "Host pool type.  Pooled (shared) or Personal (dedicated)."
  type        = string
  default     = "Pooled"

  validation {
    condition     = contains(["Pooled", "Personal"], var.avd_host_pool_type)
    error_message = "avd_host_pool_type must be 'Pooled' or 'Personal'."
  }
}

variable "avd_host_pool_load_balancer" {
  description = "Load balancing algorithm for Pooled host pools (BreadthFirst or DepthFirst)."
  type        = string
  default     = "BreadthFirst"
}

variable "avd_max_sessions_per_host" {
  description = "Maximum number of concurrent sessions per session host."
  type        = number
  default     = 10
}

variable "avd_workspace_name" {
  description = "Name of the AVD workspace."
  type        = string
  default     = "ws-avd-prod"
}

variable "avd_application_group_name" {
  description = "Name of the AVD desktop application group."
  type        = string
  default     = "dag-avd-prod"
}

# ---------------------------------------------------------------------------
# RBAC – Customer session host managers
# ---------------------------------------------------------------------------

variable "session_host_admin_object_ids" {
  description = <<-EOT
    Object IDs of users/groups that can manage session hosts and install
    applications (assigned the Virtual Machine Contributor role in the
    session host resource group).
  EOT
  type        = list(string)
  default     = []
}

variable "avd_user_object_ids" {
  description = <<-EOT
    Object IDs of users/groups that are allowed to log in to AVD
    (assigned the Desktop Virtualization User role on the application group).
  EOT
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Map of tags applied to all resources in this deployment."
  type        = map(string)
  default = {
    environment      = "production"
    workload         = "avd"
    cost_center      = "customer"
    managed_by       = "customer-team"
    compliance_scope = "fedramp-high"
  }
}

# ---------------------------------------------------------------------------
# MSIX App Attach Storage
# Customer Cost: Premium Azure Files storage (per provisioned GB/month)
# ---------------------------------------------------------------------------

variable "msix_share_size_gb" {
  description = "Quota in GB for the MSIX app attach Azure Files share."
  type        = number
  default     = 512
}
