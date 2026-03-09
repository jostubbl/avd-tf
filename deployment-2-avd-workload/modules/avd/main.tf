###############################################################################
# modules/avd/main.tf – AVD Management Plane via Azure Verified Modules (AVM)
#
# This module provisions the AVD management plane using the official Azure
# Verified Modules (AVM) from the Terraform registry:
#   - Azure/avm-res-desktopvirtualization-hostpool/azurerm        ~> 0.4
#   - Azure/avm-res-desktopvirtualization-applicationgroup/azurerm ~> 0.2
#   - Azure/avm-res-desktopvirtualization-workspace/azurerm        ~> 0.2
#
# Customer Cost:
#   - Host pools, application groups, and workspaces have NO direct Azure cost.
#   - The session host VMs (deployed separately) are the primary cost driver.
#   - Registration token lifecycle management has no cost.
#
# NOTE: In environments with limited outbound internet access, these modules
# must be pulled during the CI/CD pipeline's `terraform init` phase.
# Ensure the pipeline runner can reach registry.terraform.io, or pre-mirror
# the modules to an internal registry / vendor them with `terraform providers mirror`.
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  name_prefix = "${var.workload_name}-${var.environment}"
}

###############################################################################
# Host Pool (AVM)
# AVM source: Azure/avm-res-desktopvirtualization-hostpool/azurerm ~> 0.4
#
# The AVM host pool module internally creates and manages the registration
# info resource; the token is exposed via the `registrationinfo_token` output.
###############################################################################
module "host_pool" {
  source  = "Azure/avm-res-desktopvirtualization-hostpool/azurerm"
  version = "~> 0.4"

  resource_group_name                           = var.resource_group_name
  virtual_desktop_host_pool_resource_group_name = var.resource_group_name
  virtual_desktop_host_pool_name                = var.host_pool_name
  virtual_desktop_host_pool_location            = var.location

  virtual_desktop_host_pool_type                     = var.host_pool_type
  virtual_desktop_host_pool_load_balancer_type       = var.host_pool_load_balancer
  virtual_desktop_host_pool_maximum_sessions_allowed = var.max_sessions_per_host
  virtual_desktop_host_pool_preferred_app_group_type = "Desktop"
  virtual_desktop_host_pool_start_vm_on_connect      = false

  # Registration token validity period (ISO 8601 duration format)
  registration_expiration_period = "${var.registration_token_validity_hours}h"

  virtual_desktop_host_pool_scheduled_agent_updates = {
    enabled  = true
    timezone = "Eastern Standard Time"
    schedule = [
      {
        day_of_week = "Saturday"
        hour_of_day = 2
      }
    ]
  }

  enable_telemetry = false
  tags             = var.tags
}

###############################################################################
# Desktop Application Group (AVM)
# AVM source: Azure/avm-res-desktopvirtualization-applicationgroup/azurerm ~> 0.2
###############################################################################
module "application_group" {
  source  = "Azure/avm-res-desktopvirtualization-applicationgroup/azurerm"
  version = "~> 0.2"

  virtual_desktop_application_group_resource_group_name = var.resource_group_name
  virtual_desktop_application_group_name                = var.application_group_name
  virtual_desktop_application_group_location            = var.location
  virtual_desktop_application_group_type                = "Desktop"
  virtual_desktop_application_group_host_pool_id        = module.host_pool.resource_id

  virtual_desktop_application_group_default_desktop_display_name = "AVD Desktop"

  # Assign AVD users (Desktop Virtualization User role)
  role_assignments = {
    for idx, oid in var.avd_user_object_ids : "avd-user-${idx}" => {
      role_definition_id_or_name = "Desktop Virtualization User"
      principal_id               = oid
    }
  }

  virtual_desktop_application_group_tags = var.tags
  enable_telemetry                       = false

  depends_on = [module.host_pool]
}

###############################################################################
# Workspace (AVM)
# AVM source: Azure/avm-res-desktopvirtualization-workspace/azurerm ~> 0.2
###############################################################################
module "workspace" {
  source  = "Azure/avm-res-desktopvirtualization-workspace/azurerm"
  version = "~> 0.2"

  virtual_desktop_workspace_resource_group_name = var.resource_group_name
  virtual_desktop_workspace_name                = var.workspace_name
  virtual_desktop_workspace_location            = var.location
  virtual_desktop_workspace_description         = "AVD Workspace – ${local.name_prefix}"
  virtual_desktop_workspace_friendly_name       = "AVD Workspace (${upper(var.environment)})"

  virtual_desktop_workspace_tags = var.tags
  enable_telemetry               = false

  depends_on = [module.application_group]
}

###############################################################################
# Workspace ↔ Application Group Association
###############################################################################
resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  workspace_id         = module.workspace.resource_id
  application_group_id = module.application_group.resource_id

  depends_on = [module.workspace, module.application_group]
}
