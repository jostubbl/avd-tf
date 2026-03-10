###############################################################################
# modules/compute/variables.tf – JUCE Compute Module
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group in which to create compute resources."
  type        = string
}

variable "location" {
  description = "Azure Government region for compute resources."
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

variable "vm_count" {
  description = "Number of JUCE virtual machines to deploy."
  type        = number
}

variable "vm_size" {
  description = "Azure VM size/SKU for JUCE virtual machines."
  type        = string
}

variable "vm_os_disk_type" {
  description = "Managed disk type for the OS disk."
  type        = string
}

variable "vm_image" {
  description = "Marketplace image for JUCE virtual machines."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "vm_subnet_id" {
  description = "Resource ID of the subnet to attach VM network interfaces to."
  type        = string
}

variable "admin_username" {
  description = "Local administrator username."
  type        = string
}

variable "admin_password" {
  description = "Local administrator password."
  type        = string
  sensitive   = true
}

variable "availability_zone" {
  description = "List of availability zones for VM distribution.  Empty list uses an availability set instead."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all compute resources."
  type        = map(string)
  default     = {}
}
