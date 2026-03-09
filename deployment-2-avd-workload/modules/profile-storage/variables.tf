###############################################################################
# modules/profile-storage/variables.tf
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group for storage resources."
  type        = string
}

variable "location" {
  description = "Azure Government region for storage resources."
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

variable "fslogix_share_size_gb" {
  description = "Quota in GB for the FSLogix Azure Files share."
  type        = number
  default     = 1024
}

variable "storage_account_replication" {
  description = "Storage account replication type (LRS, ZRS, GRS, GZRS)."
  type        = string
  default     = "ZRS"
}

variable "private_endpoint_subnet_id" {
  description = "Resource ID of the subnet to place the private endpoint in."
  type        = string
}

variable "private_dns_zone_resource_group" {
  description = "Resource group that contains the Azure Files private DNS zone."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all storage resources."
  type        = map(string)
  default     = {}
}
