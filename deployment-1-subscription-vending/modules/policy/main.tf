###############################################################################
# modules/policy/main.tf – Management Group Policy Assignments
#
# Platform Responsibility: Policy assignments at MG scope ensure that all
# workload subscriptions placed under the MG inherit compliance controls.
#
# Built-in initiative IDs (same in Azure Government and Azure Commercial):
#   FedRAMP High:                  d5264498-16f4-418a-b659-fa7ef418175f
#   NIST SP 800-53 Rev 5:          179d1daa-458f-4e47-8086-2a68d0d6c38f
#   MS Cloud Security Benchmark:   1f3afdf9-d0c9-4c3d-847f-89da613e70a8
###############################################################################

locals {
  mg_resource_id = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
}

###############################################################################
# FedRAMP High initiative assignment
###############################################################################
resource "azurerm_management_group_policy_assignment" "fedramp_high" {
  count = var.assign_fedramp_high ? 1 : 0

  name                 = "fedramp-high"
  display_name         = "FedRAMP High"
  management_group_id  = local.mg_resource_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/d5264498-16f4-418a-b659-fa7ef418175f"
  location             = var.location
  enforce              = var.policy_enforcement_mode == "Default"

  # SystemAssigned identity enables auto-remediation for DeployIfNotExists policies
  identity {
    type = "SystemAssigned"
  }
}

###############################################################################
# NIST SP 800-53 Rev 5 initiative assignment
###############################################################################
resource "azurerm_management_group_policy_assignment" "nist_800_53_r5" {
  count = var.assign_nist_800_53_r5 ? 1 : 0

  name                 = "nist-800-53-r5"
  display_name         = "NIST SP 800-53 Rev 5"
  management_group_id  = local.mg_resource_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
  location             = var.location
  enforce              = var.policy_enforcement_mode == "Default"

  identity {
    type = "SystemAssigned"
  }
}

###############################################################################
# Microsoft Cloud Security Benchmark initiative assignment
###############################################################################
resource "azurerm_management_group_policy_assignment" "mcsb" {
  count = var.assign_azure_security_benchmark ? 1 : 0

  name                 = "mcsb"
  display_name         = "Microsoft Cloud Security Benchmark"
  management_group_id  = local.mg_resource_id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
  location             = var.location
  enforce              = var.policy_enforcement_mode == "Default"

  identity {
    type = "SystemAssigned"
  }
}
