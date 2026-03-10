###############################################################################
# modules/networking/variables.tf – JUCE Networking Module
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group in which to create networking resources."
  type        = string
}

variable "location" {
  description = "Azure Government region for networking resources."
  type        = string
}

variable "workload_name" {
  description = "Short workload name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (sandbox or production)."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space CIDR(s) for the JUCE spoke VNet."
  type        = list(string)
}

variable "vm_subnet_address_prefix" {
  description = "CIDR for the JUCE VM subnet."
  type        = string
}

variable "private_endpoint_subnet_address_prefix" {
  description = "CIDR for the private endpoint subnet."
  type        = string
}

variable "hub_vnet_id" {
  description = "(Optional) Resource ID of the hub VNet for peering.  Empty string skips peering."
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "Custom DNS server IP addresses.  Empty list uses Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all networking resources."
  type        = map(string)
  default     = {}
}
