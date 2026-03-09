###############################################################################
# modules/networking/variables.tf
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group for networking resources."
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
  description = "Short environment name used in resource naming."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space CIDR(s) for the spoke VNet."
  type        = list(string)
}

variable "session_host_subnet_cidr" {
  description = "CIDR for the AVD session host subnet."
  type        = string
}

variable "private_endpoint_subnet_cidr" {
  description = "CIDR for the private endpoint subnet."
  type        = string
}

variable "dns_servers" {
  description = "Custom DNS server IPs (e.g. hub DNS forwarders)."
  type        = list(string)
  default     = []
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet to peer with.  Empty string skips peering."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all networking resources."
  type        = map(string)
  default     = {}
}
