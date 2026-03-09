###############################################################################
# modules/session-hosts/variables.tf
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group for session host VMs."
  type        = string
}

variable "location" {
  description = "Azure Government region for session host VMs."
  type        = string
}

variable "workload_name" {
  description = "Short workload name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Short environment name used in resource naming."
  type        = string
}

variable "session_host_count" {
  description = "Number of session host VMs to deploy."
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Azure VM SKU for session hosts."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "os_disk_type" {
  description = "Storage type for the OS disk (Premium_LRS, StandardSSD_LRS, Standard_LRS)."
  type        = string
  default     = "Premium_LRS"
}

variable "image" {
  description = "Marketplace image reference for session host VMs."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "local_admin_username" {
  description = "Local administrator username."
  type        = string
  default     = "avdadmin"
}

variable "local_admin_password" {
  description = "Local administrator password.  Supplied via CI/CD secret."
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "Resource ID of the subnet to attach session host NICs to."
  type        = string
}

variable "host_pool_name" {
  description = "Name of the AVD host pool this session host will register with (used in DSC extension settings)."
  type        = string
}

variable "host_pool_registration_token" {
  description = "Registration token for joining session hosts to the AVD host pool."
  type        = string
  sensitive   = true
}

variable "domain_join_type" {
  description = "Directory join method: 'AAD' (Entra ID) or 'ADDS' (Active Directory)."
  type        = string
  default     = "AAD"
}

variable "domain_name" {
  description = "FQDN of the AD domain (only for ADDS join)."
  type        = string
  default     = ""
}

variable "domain_join_username" {
  description = "UPN of the domain-join service account (only for ADDS join)."
  type        = string
  default     = ""
}

variable "domain_join_password" {
  description = "Password of the domain-join service account (only for ADDS join)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "domain_ou_path" {
  description = "OU path for computer accounts (only for ADDS join)."
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Name of the FSLogix storage account (for FSLogix configuration script)."
  type        = string
}

variable "fslogix_share_name" {
  description = "Name of the FSLogix Azure Files share."
  type        = string
}

variable "avd_dsc_configuration_url" {
  description = <<-EOT
    URL to the AVD DSC agent configuration ZIP file.
    Defaults to the Azure Government blob endpoint for the latest stable version.
    Override this to pin a specific version or use a mirrored copy in restricted environments.
  EOT
  type        = string
  default     = "https://wvdportalstorageblob.blob.core.usgovcloudapi.net/galleryartifacts/Configuration.zip"
}

variable "tags" {
  description = "Tags to apply to all session host resources."
  type        = map(string)
  default     = {}
}
