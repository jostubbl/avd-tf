###############################################################################
# main.tf – Deployment 1: Platform / Subscription Vending
#
# Platform Responsibility: All resources in this file are owned and operated
# by the central platform team.  NONE of these resources generate direct
# customer costs – the subscription itself is a billing boundary container.
#
# Customer Cost Boundary: The subscription created here is the billing scope
# for all customer workload costs.  Everything deployed inside it (see
# deployment-2-avd-workload) is billable to the customer.
###############################################################################

###############################################################################
# 1. Vend a new Azure Subscription
#    Cost attribution: None – subscription is a free billing container.
#    Platform responsibility: Platform team owns the EA billing scope.
###############################################################################
resource "azurerm_subscription" "avd_workload" {
  subscription_name = var.subscription_name
  billing_scope_id  = var.billing_scope_id
  workload          = var.subscription_workload

  tags = var.tags
}

###############################################################################
# 2. Place the subscription under the correct ALZ Management Group
#    This inherits:
#      - Azure Policy (compliance, security baselines)
#      - Diagnostics / logging settings
#      - Connectivity (hub peering via platform policies if applicable)
#    Platform responsibility: Platform team manages ALZ hierarchy.
###############################################################################
resource "azurerm_management_group_subscription_association" "avd_workload" {
  management_group_id = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  subscription_id     = azurerm_subscription.avd_workload.id

  # Must wait for the subscription to be fully provisioned before association.
  depends_on = [azurerm_subscription.avd_workload]
}

###############################################################################
# 3. RBAC – Customer Technical Owners (Owner at subscription scope)
#    Allows the customer's engineering team to manage workload resources.
#    Platform responsibility: Platform team creates the assignment;
#    customer team assumes operational ownership.
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
#    Provides read-only access to cost and billing data for the subscription.
#    Platform responsibility: Platform team creates the assignment.
###############################################################################
resource "azurerm_role_assignment" "finance_ops" {
  for_each = toset(var.finance_ops_object_ids)

  scope                = azurerm_subscription.avd_workload.id
  role_definition_name = "Cost Management Reader"
  principal_id         = each.value

  depends_on = [azurerm_subscription.avd_workload]
}

###############################################################################
# 5. Subscription-level Monthly Budget with Alert Thresholds
#    Enforces cost accountability at the subscription (customer) boundary.
#    Alerts fire at 80 % and 100 % of the monthly budget.
#    Platform responsibility: Platform team configures budget policy;
#    customer team is notified and accountable for costs.
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

  # Alert at 80 % of budget (forecasted)
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.budget_alert_emails
  }

  # Alert at 100 % of budget (actual)
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_alert_emails
  }

  depends_on = [azurerm_subscription.avd_workload]
}
