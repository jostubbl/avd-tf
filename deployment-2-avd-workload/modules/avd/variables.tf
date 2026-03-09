###############################################################################
# modules/avd/variables.tf
###############################################################################

variable "resource_group_name" {
  description = "Name of the resource group for AVD management plane resources."
  type        = string
}

variable "location" {
  description = "Azure Government region for AVD resources."
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

variable "host_pool_name" {
  description = "Name of the AVD host pool."
  type        = string
}

variable "host_pool_type" {
  description = "Host pool type: Pooled or Personal."
  type        = string
  default     = "Pooled"
}

variable "host_pool_load_balancer" {
  description = "Load balancing algorithm (BreadthFirst or DepthFirst).  Used only for Pooled host pools."
  type        = string
  default     = "BreadthFirst"
}

variable "max_sessions_per_host" {
  description = "Maximum number of concurrent sessions per session host."
  type        = number
  default     = 10
}

variable "workspace_name" {
  description = "Name of the AVD workspace."
  type        = string
}

variable "application_group_name" {
  description = "Name of the AVD desktop application group."
  type        = string
}

variable "registration_token_validity_hours" {
  description = "Validity period in hours for the host pool registration token."
  type        = number
  default     = 48
}

variable "avd_user_object_ids" {
  description = "Object IDs of users/groups granted the Desktop Virtualization User role on the application group."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all AVD resources."
  type        = map(string)
  default     = {}
}
