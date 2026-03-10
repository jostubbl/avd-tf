###############################################################################
# main.tf – Deployment 1: JUCE Subscription + Baseline Configuration
#
# This deployment:
#   1. Creates or imports the JUCE workload subscription with required tags
#   2. (Optional) Places the subscription under the ALZ management group
#   3. Enables Microsoft Defender for Cloud plans:
#        - Defender CSPM
#        - Cloud Workload Protection (CWPP) – All plans
#        - Servers (P1 – without Defender Sensor)
#        - Databases (SQL servers, SQL Server VMs, Open Source DBs, Cosmos DB)
#        - Storage
#        - Containers (without Defender Sensor – see note below)
#        - Resource Manager
#        - Additional CWPP plans: App Services, Key Vaults, DNS
#   4. Configures FIM to send data to a centralized Log Analytics Workspace
#   5. Assigns the NIST SP 800-53 Rev. 5 Security Policy initiative
#
# Does NOT deploy:
#   - Virtual machines
#   - Virtual networks
#   - Storage accounts
#   - Key Vaults
###############################################################################

locals {
  subscription_tags = {
    agency            = var.tag_agency
    program-office    = var.tag_program_office
    charge-site       = var.tag_charge_site
    project           = var.tag_project
    application-owner = var.tag_application_owner
    account           = var.tag_account
    environment       = var.environment
  }

  # Workload type maps the environment parameter to Azure subscription workload
  subscription_workload = var.environment == "production" ? "Production" : "DevTest"

  # Defender, FIM, and NIST policy resources are only configured when the
  # workload subscription ID is known.  This supports the two-phase pattern for
  # new subscriptions: Phase 1 creates the subscription; Phase 2 configures it.
  configure_subscription = var.workload_subscription_id != ""
}

###############################################################################
# 1. Subscription – create new or manage existing
#    - If billing_scope_id is set: creates a new JUCE workload subscription.
#    - If billing_scope_id is empty: imports and manages an existing subscription
#      (updates display name and tags without changing billing configuration).
###############################################################################
resource "azurerm_subscription" "juce" {
  provider = azurerm.management

  # Required for both new and existing subscriptions
  subscription_name = var.subscription_name

  # Create a new subscription when billing scope is provided
  billing_scope_id = var.billing_scope_id != "" ? var.billing_scope_id : null

  # Manage an existing subscription when no billing scope is provided
  subscription_id = var.billing_scope_id == "" ? var.workload_subscription_id : null

  workload = local.subscription_workload

  tags = local.subscription_tags
}

###############################################################################
# 2. Management Group association (optional)
#    Places the subscription under the ALZ MG hierarchy so it inherits
#    platform-level Azure Policies and governance controls.
###############################################################################
resource "azurerm_management_group_subscription_association" "juce" {
  count = var.management_group_id != "" ? 1 : 0

  management_group_id = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  subscription_id     = azurerm_subscription.juce.id

  depends_on = [azurerm_subscription.juce]
}

###############################################################################
# 3. Microsoft Defender for Cloud – CSPM
#    Defender Cloud Security Posture Management provides continuous assessment
#    of cloud security posture, security recommendations, and compliance.
#    Resource type "CloudPosture" maps to Defender CSPM in the azurerm provider.
###############################################################################
resource "azurerm_security_center_subscription_pricing" "cspm" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "CloudPosture"
}

###############################################################################
# 4. Microsoft Defender for Cloud – CWPP: Servers
#    Subplan P1 enables server protection WITHOUT the Defender Sensor
#    (MDE integration / full endpoint detection), as required.
#    P2 would include the Defender Sensor; P1 excludes it.
###############################################################################
resource "azurerm_security_center_subscription_pricing" "servers" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "VirtualMachines"
  subplan       = "P1"
}

###############################################################################
# 5. Microsoft Defender for Cloud – CWPP: Databases
#    All four database sub-plans are enabled to satisfy "Databases" in CWPP-All.
###############################################################################

# Defender for Azure SQL Databases
resource "azurerm_security_center_subscription_pricing" "sql_servers" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "SqlServers"
}

# Defender for SQL Server Virtual Machines
resource "azurerm_security_center_subscription_pricing" "sql_server_vms" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "SqlServerVirtualMachines"
}

# Defender for Open Source Relational Databases (PostgreSQL, MySQL, MariaDB)
resource "azurerm_security_center_subscription_pricing" "open_source_dbs" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "OpenSourceRelationalDatabases"
}

# Defender for Azure Cosmos DB
resource "azurerm_security_center_subscription_pricing" "cosmos_dbs" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "CosmosDbs"
}

###############################################################################
# 6. Microsoft Defender for Cloud – CWPP: Storage
###############################################################################
resource "azurerm_security_center_subscription_pricing" "storage" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

###############################################################################
# 7. Microsoft Defender for Cloud – CWPP: Containers
#    NOTE on Defender Sensor: The Defender Sensor (DaemonSet deployed to AKS
#    clusters) is configured per-cluster via the Kubernetes extension resource
#    (azurerm_kubernetes_cluster_extension) and cannot be globally disabled at
#    the subscription level through this resource.  Exclude the Defender Sensor
#    extension when provisioning individual AKS clusters in Deployment 2.
###############################################################################
resource "azurerm_security_center_subscription_pricing" "containers" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "Containers"
}

###############################################################################
# 8. Microsoft Defender for Cloud – CWPP: Resource Manager
###############################################################################
resource "azurerm_security_center_subscription_pricing" "arm" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "Arm"
}

###############################################################################
# 9. Microsoft Defender for Cloud – CWPP: Additional plans (CWPP-All)
#    App Services, Key Vaults, and DNS are included to satisfy the "All" scope
#    of the Cloud Workload Protection requirement.
###############################################################################

resource "azurerm_security_center_subscription_pricing" "app_services" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "AppServices"
}

resource "azurerm_security_center_subscription_pricing" "key_vaults" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "dns" {
  count         = local.configure_subscription ? 1 : 0
  tier          = "Standard"
  resource_type = "Dns"
}

###############################################################################
# 10. FIM – File Integrity Monitoring
#     Configures Defender for Cloud to forward all security data (including
#     FIM events) to the CENTRALIZED Log Analytics Workspace specified by
#     var.log_analytics_workspace_id.
###############################################################################

# Point Defender for Cloud security data collection to the centralized LAW
resource "azurerm_security_center_workspace" "fim" {
  count        = local.configure_subscription ? 1 : 0
  scope        = azurerm_subscription.juce.id
  workspace_id = var.log_analytics_workspace_id
}

###############################################################################
# 11. Security Policy – NIST SP 800-53 Rev. 5
#     Assigns the built-in NIST SP 800-53 Rev. 5 policy initiative directly to
#     the JUCE workload subscription.  A system-assigned managed identity is
#     required for policy remediation tasks.
###############################################################################

# Look up the built-in NIST SP 800-53 Rev. 5 initiative definition
data "azurerm_policy_set_definition" "nist_800_53_r5" {
  count        = local.configure_subscription ? 1 : 0
  display_name = "NIST SP 800-53 Rev. 5"
}

resource "azurerm_subscription_policy_assignment" "nist_800_53_r5" {
  count                = local.configure_subscription ? 1 : 0
  name                 = "nist-sp-800-53-rev5"
  display_name         = "NIST SP 800-53 Rev. 5"
  policy_definition_id = data.azurerm_policy_set_definition.nist_800_53_r5[0].id
  subscription_id      = azurerm_subscription.juce.id

  # Location is required for managed identity-backed policy assignments
  location = var.location

  # System-assigned identity enables Defender / policy remediation tasks
  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_subscription.juce]
}
