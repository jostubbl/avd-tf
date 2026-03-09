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
# 1. Vend a new Azure Subscription
#    Customer billing boundary; subscription itself has no direct cost.
###############################################################################
resource "azurerm_subscription" "avd_workload" {
  subscription_name = var.subscription_name
  billing_scope_id  = var.billing_scope_id
  workload          = var.subscription_workload

  tags = var.tags
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
#    These are the connectivity and identity resource groups owned by the
#    platform team.  All hub resources are isolated from customer workloads.
###############################################################################
resource "azurerm_resource_group" "connectivity" {
  name     = "rg-platform-connectivity-${var.platform_location}"
  location = var.platform_location
  tags     = merge(var.tags, { cost_center = "platform", resource_group = "connectivity" })
}

resource "azurerm_resource_group" "identity" {
  name     = "rg-platform-identity-${var.platform_location}"
  location = var.platform_location
  tags     = merge(var.tags, { cost_center = "platform", resource_group = "identity" })
}

###############################################################################
# 7. Module: hub-networking
#    Deploys the central hub VNet, Azure Firewall, optional VPN Gateway and
#    Azure Bastion in the platform subscription's connectivity resource group.
#    Platform Cost: Firewall, gateway, and Bastion charges billed to platform.
###############################################################################
module "hub_networking" {
  source = "./modules/hub-networking"

  resource_group_name        = azurerm_resource_group.connectivity.name
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
  tags                       = var.tags

  depends_on = [azurerm_resource_group.connectivity]
}

###############################################################################
# 8. Module: identity
#    Deploys Azure AD Domain Services (AADDS) as the shared managed domain
#    for all workload subscriptions.  Session hosts in D2 join this domain.
#    Platform Cost: AADDS hourly charge billed to platform.
###############################################################################
module "identity" {
  source = "./modules/identity"

  resource_group_name       = azurerm_resource_group.identity.name
  location                  = var.platform_location
  identity_subnet_id        = module.hub_networking.identity_subnet_id
  deploy_aadds              = var.deploy_aadds
  aadds_domain_name         = var.aadds_domain_name
  aadds_sku                 = var.aadds_sku
  aadds_notification_emails = var.aadds_notification_emails
  tags                      = var.tags

  depends_on = [
    azurerm_resource_group.identity,
    module.hub_networking,
  ]
}

###############################################################################
# 9. Module: policy
#    Assigns FedRAMP High, NIST SP 800-53 Rev 5, and Microsoft Cloud Security
#    Benchmark initiatives at the ALZ management group scope.
#    All vended subscriptions placed under the MG inherit these assignments.
###############################################################################
module "policy" {
  source = "./modules/policy"

  management_group_id             = var.management_group_id
  location                        = var.platform_location
  assign_fedramp_high             = var.assign_fedramp_high
  assign_nist_800_53_r5           = var.assign_nist_800_53_r5
  assign_azure_security_benchmark = var.assign_azure_security_benchmark
  policy_enforcement_mode         = var.policy_enforcement_mode
  tags                            = var.tags

  depends_on = [azurerm_management_group_subscription_association.avd_workload]
}
