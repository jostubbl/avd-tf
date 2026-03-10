###############################################################################
# variables.tf – Deployment 2: JUCE Customer VM Workload
###############################################################################

# ---------------------------------------------------------------------------
# Core deployment context
# ---------------------------------------------------------------------------

variable "subscription_id" {
  description = "The UUID of the JUCE workload subscription (output of Deployment 1)."
  type        = string
}

variable "location" {
  description = "Azure Government region for all JUCE VM resources.  Must be usgovarizona."
  type        = string
  default     = "usgovarizona"

  validation {
    condition     = var.location == "usgovarizona"
    error_message = "All JUCE deployments must target usgovarizona."
  }
}

variable "environment" {
  description = "Deployment environment.  Allowed values: sandbox, production."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["sandbox", "production"], var.environment)
    error_message = "environment must be 'sandbox' or 'production'."
  }
}

variable "workload_name" {
  description = "Short name used in resource naming (e.g. 'juce').  Lower-case alphanumeric and hyphens only."
  type        = string
  default     = "juce"
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space CIDR(s) for the JUCE spoke VNet."
  type        = list(string)
  default     = ["10.200.0.0/16"]
}

variable "vm_subnet_address_prefix" {
  description = "CIDR for the JUCE VM subnet."
  type        = string
  default     = "10.200.1.0/24"
}

variable "private_endpoint_subnet_address_prefix" {
  description = "CIDR for the private endpoint subnet."
  type        = string
  default     = "10.200.2.0/24"
}

variable "hub_vnet_id" {
  description = "(Optional) Resource ID of the platform hub VNet for peering.  Leave empty to skip VNet peering."
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "(Optional) List of custom DNS server IP addresses.  Leave empty to use Azure-provided DNS."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Virtual Machines
# ---------------------------------------------------------------------------

variable "vm_count" {
  description = "Number of JUCE virtual machines to deploy."
  type        = number
  default     = 2

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 50
    error_message = "vm_count must be between 1 and 50."
  }
}

variable "vm_size" {
  description = "Azure VM size/SKU.  Must be available in Azure Government (usgovarizona)."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "vm_os_disk_type" {
  description = "Managed disk type for the OS disk.  Allowed: Premium_LRS, StandardSSD_LRS, Standard_LRS."
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Premium_LRS", "StandardSSD_LRS", "Standard_LRS"], var.vm_os_disk_type)
    error_message = "vm_os_disk_type must be Premium_LRS, StandardSSD_LRS, or Standard_LRS."
  }
}

variable "vm_image" {
  description = "Marketplace image for JUCE virtual machines."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}

variable "admin_username" {
  description = "Local administrator username for JUCE virtual machines."
  type        = string
  default     = "juceadmin"
}

variable "admin_password" {
  description = "Local administrator password for JUCE virtual machines.  Supply via CI/CD secret variable."
  type        = string
  sensitive   = true
}

variable "availability_zone" {
  description = "(Optional) Availability zone(s) for JUCE VMs.  Provide a list to distribute across zones (e.g. [\"1\",\"2\",\"3\"]).  Leave empty for no zone pinning."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Required subscription tags (inherited from Deployment 1)
# ---------------------------------------------------------------------------

variable "tag_agency" {
  description = "Tag: agency — the government agency that owns this workload."
  type        = string
}

variable "tag_program_office" {
  description = "Tag: program-office — the program office responsible for this workload."
  type        = string
}

variable "tag_charge_site" {
  description = "Tag: charge-site — the cost center or charge site for billing purposes."
  type        = string
}

variable "tag_project" {
  description = "Tag: project — the project name or identifier associated with this workload."
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
