###############################################################################
# main.tf – Deployment 1: Platform / Subscription Vending
#
# Platform Responsibility: All resources in this file are owned and operated
# by the central platform team.  They establish the governance, connectivity,
# and identity foundation that all workload subscriptions inherit.
#
# Cost Attribution:
#   - Subscription, MG, RBAC, budget:  No direct compute/storage cost.
#   - Hub networking (Firewall, Gateway, Bastion):  Platform budget.
#   - Identity (AADDS):  Platform budget.
#   - Policy assignments:  No direct cost.
###############################################################################

###############################################################################
# Locals
###############################################################################

locals {
  # Map environment (sandbox/production) to Azure subscription workload type
  subscription_workload = var.environment == "sandbox" ? "DevTest" : "Production"

  # Required subscription tags (must always be present)
  required_tags = {
    agency            = var.tag_agency
    program-office    = var.tag_program_office
    charge-site       = var.tag_charge_site
    project           = var.tag_project
    application-owner = var.tag_application_owner
    account           = var.tag_account
  }

  # Merge required tags with any supplementary tags; required tags take precedence
  all_tags = merge(var.tags, local.required_tags)
}

###############################################################################
# 1. Vend a new Azure Subscription
#    Customer billing boundary; subscription itself has no direct cost.
###############################################################################
resource "azurerm_subscription" "avd_workload" {
  subscription_name = var.subscription_name
  billing_scope_id  = var.billing_scope_id
  workload          = local.subscription_workload

  tags = local.all_tags
}

###############################################################################
# 2. Place the subscription under the correct ALZ Management Group
#    Inherits policy, diagnostics, and networking policies from MG hierarchy.
###############################################################################
resource "azurerm_management_group_subscription_association" "avd_workload" {
  management_group_id = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  subscription_id     = azurerm_subscription.avd_workload.id

  depends_on = [azurerm_subscription.avd_workload]
}

###############################################################################
# 3. RBAC – Customer Technical Owners (Owner at subscription scope)
###############################################################################
resource "azurerm_role_assignment" "technical_owner" {
  for_each = toset(var.technical_owner_object_ids)

  scope                = azurerm_subscription.avd_workload.id
  role_definition_name = "Owner"
  principal_id         = each.value

  depends_on = [azurerm_subscription.avd_workload]
}

###############################################################################
# 4. RBAC – Customer Finance / Ops (Cost Management Reader)
###############################################################################
resource "azurerm_role_assignment" "finance_ops" {
  for_each = toset(var.finance_ops_object_ids)

  scope                = azurerm_subscription.avd_workload.id
  role_definition_name = "Cost Management Reader"
  principal_id         = each.value

  depends_on = [azurerm_subscription.avd_workload]
}

###############################################################################
# 5. Subscription-level Monthly Budget
#    Alerts at 80 % (forecasted) and 100 % (actual).
###############################################################################
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = var.budget_name
  subscription_id = azurerm_subscription.avd_workload.id

  amount     = var.budget_amount_usd
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
    end_date   = var.budget_end_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.budget_alert_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_alert_emails
  }

  depends_on = [azurerm_subscription.avd_workload]
}

###############################################################################
# 6. Resource Groups (in the platform subscription)
#    Connectivity and identity resource groups are only created when
#    deploy_hub_networking = true.  By default these are skipped because
#    Deployment 1 does not deploy Virtual Networks (per spec constraints).
###############################################################################
resource "azurerm_resource_group" "connectivity" {
  count = var.deploy_hub_networking ? 1 : 0

  name     = "rg-platform-connectivity-${var.platform_location}"
  location = var.platform_location
  tags     = merge(local.all_tags, { cost_center = "platform", resource_group = "connectivity" })
}

resource "azurerm_resource_group" "identity" {
  count = var.deploy_hub_networking ? 1 : 0

  name     = "rg-platform-identity-${var.platform_location}"
  location = var.platform_location
  tags     = merge(local.all_tags, { cost_center = "platform", resource_group = "identity" })
}

###############################################################################
# 7. Module: hub-networking  (optional – deploy_hub_networking = false by default)
#    When enabled, deploys the central hub VNet, Azure Firewall, optional VPN
#    Gateway and Azure Bastion in the platform subscription's connectivity RG.
###############################################################################
module "hub_networking" {
  count  = var.deploy_hub_networking ? 1 : 0
  source = "./modules/hub-networking"

  resource_group_name        = azurerm_resource_group.connectivity[0].name
  location                   = var.platform_location
  workload_name              = "platform"
  hub_vnet_address_space     = var.hub_vnet_address_space
  firewall_subnet_cidr       = var.firewall_subnet_cidr
  gateway_subnet_cidr        = var.gateway_subnet_cidr
  bastion_subnet_cidr        = var.bastion_subnet_cidr
  identity_subnet_cidr       = var.identity_subnet_cidr
  management_subnet_cidr     = var.management_subnet_cidr
  firewall_sku_tier          = var.firewall_sku_tier
  firewall_threat_intel_mode = var.firewall_threat_intel_mode
  deploy_vpn_gateway         = var.deploy_vpn_gateway
  vpn_gateway_sku            = var.vpn_gateway_sku
  deploy_bastion             = var.deploy_bastion
  bastion_sku                = var.bastion_sku
  tags                       = local.all_tags

  depends_on = [azurerm_resource_group.connectivity]
}

###############################################################################
# 8. Module: identity  (optional – depends on deploy_hub_networking)
#    Deploys Azure AD Domain Services (AADDS) when both deploy_hub_networking
#    and deploy_aadds are true.
###############################################################################
module "identity" {
  count  = var.deploy_hub_networking ? 1 : 0
  source = "./modules/identity"

  resource_group_name       = azurerm_resource_group.identity[0].name
  location                  = var.platform_location
  identity_subnet_id        = module.hub_networking[0].identity_subnet_id
  deploy_aadds              = var.deploy_aadds
  aadds_domain_name         = var.aadds_domain_name
  aadds_sku                 = var.aadds_sku
  aadds_notification_emails = var.aadds_notification_emails
  tags                      = local.all_tags

  depends_on = [
    azurerm_resource_group.identity,
    module.hub_networking,
  ]
}

###############################################################################
# 9. Module: policy
#    Assigns FedRAMP High, NIST SP 800-53 Rev 5, and Microsoft Cloud Security
#    Benchmark initiatives at the ALZ management group scope.
###############################################################################
module "policy" {
  source = "./modules/policy"

  management_group_id             = var.management_group_id
  location                        = var.platform_location
  assign_fedramp_high             = var.assign_fedramp_high
  assign_nist_800_53_r5           = var.assign_nist_800_53_r5
  assign_azure_security_benchmark = var.assign_azure_security_benchmark
  policy_enforcement_mode         = var.policy_enforcement_mode
  tags                            = local.all_tags

  depends_on = [azurerm_management_group_subscription_association.avd_workload]
}

###############################################################################
# 10. Module: defender
#     Enables Microsoft Defender for Cloud plans and NIST SP 800-53 Rev. 5
#     security policy at subscription scope.  Configures FIM to send data to
#     the centralized Log Analytics Workspace (var.law_id).
###############################################################################
module "defender" {
  source = "./modules/defender"

  location = var.platform_location
  law_id   = var.law_id
  tags     = local.all_tags

  depends_on = [azurerm_subscription.avd_workload]
}
