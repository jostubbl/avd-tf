###############################################################################
# modules/msix-storage/variables.tf – MSIX App Attach Storage
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group for MSIX storage resources (typically the storage RG)."
  type        = string
}

variable "location" {
  description = "Azure Government region for MSIX storage resources."
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

variable "msix_share_size_gb" {
  description = "Quota in GB for the MSIX packages Azure Files share.  Must accommodate all MSIX/MSIXAAB packages."
  type        = number
  default     = 512
}

variable "storage_account_replication" {
  description = "Replication type for the MSIX storage account (LRS, ZRS, GRS, GZRS)."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS"], var.storage_account_replication)
    error_message = "storage_account_replication must be LRS, ZRS, GRS, or GZRS."
  }
}

variable "private_endpoint_subnet_id" {
  description = "Resource ID of the subnet to place the private endpoint in."
  type        = string
}

variable "private_dns_zone_resource_group" {
  description = "Resource group that contains the Azure Files private DNS zone."
  type        = string
}

variable "session_host_vm_principal_ids" {
  description = <<-EOT
    List of system-assigned managed identity principal IDs for session host VMs.
    These receive the 'Storage File Data SMB Share Elevated Contributor' role so
    that the MSIX App Attach staging agent can mount packages.
  EOT
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all MSIX storage resources."
  type        = map(string)
  default     = {}
}
