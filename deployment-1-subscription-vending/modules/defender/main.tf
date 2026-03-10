###############################################################################
# modules/defender/main.tf – Microsoft Defender for Cloud Plans
#
# Platform Responsibility: Enables Defender for Cloud plans and security
# policies at subscription scope per the required configuration.
#
# Plans enabled:
#   - Defender CSPM (Cloud Security Posture Management)
#   - Defender for Servers P2 (without Defender Sensor auto-provisioning)
#   - Defender for Databases – All (SQL, SQL-on-VM, OSS DBs, Cosmos DB)
#   - Defender for Storage
#   - Defender for Containers (without Defender Sensor / DaemonSet)
#   - Defender for Resource Manager
#   - Defender for App Services  (CWPP – All)
#   - Defender for DNS            (CWPP – All)
#
# Security Policy:
#   - NIST SP 800-53 Rev. 5 assigned at subscription scope
#
# File Integrity Monitoring (FIM):
#   - Security data routed to the centralized Log Analytics Workspace
#   - Auto-provisioning of the Log Analytics agent enabled
###############################################################################

data "azurerm_client_config" "current" {}

locals {
  subscription_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}

###############################################################################
# 1. Defender CSPM
###############################################################################
resource "azurerm_security_center_subscription_pricing" "cspm" {
  pricing_tier  = "Standard"
  resource_type = "CloudPosture"
}

###############################################################################
# 2. Defender for Servers – Plan 2
#    The Defender Sensor (Microsoft Defender for Endpoint auto-provisioning)
#    is NOT enabled via auto_provisioning to comply with the requirement of
#    "Servers (except Defender Sensor)".  MDE can be deployed selectively to
#    individual VMs if required.
###############################################################################
resource "azurerm_security_center_subscription_pricing" "servers" {
  pricing_tier  = "Standard"
  resource_type = "Servers"
  subplan       = "P2"
}

###############################################################################
# 3. Defender for Databases – All
###############################################################################

# Azure SQL Databases
resource "azurerm_security_center_subscription_pricing" "sql_servers" {
  pricing_tier  = "Standard"
  resource_type = "SqlServers"
}

# SQL Server on Virtual Machines
resource "azurerm_security_center_subscription_pricing" "sql_server_vms" {
  pricing_tier  = "Standard"
  resource_type = "SqlServerVirtualMachines"
}

# Open-Source Relational Databases (MySQL, PostgreSQL, MariaDB on Azure)
resource "azurerm_security_center_subscription_pricing" "oss_dbs" {
  pricing_tier  = "Standard"
  resource_type = "OpenSourceRelationalDatabases"
}

# Azure Cosmos DB
resource "azurerm_security_center_subscription_pricing" "cosmos_db" {
  pricing_tier  = "Standard"
  resource_type = "CosmosDbs"
}

###############################################################################
# 4. Defender for Storage
###############################################################################
resource "azurerm_security_center_subscription_pricing" "storage" {
  pricing_tier  = "Standard"
  resource_type = "StorageAccounts"
}

###############################################################################
# 5. Defender for Containers
#    The Defender Sensor (DaemonSet) is not auto-provisioned per the
#    "Containers (except Defender Sensor)" requirement.  Agentless scanning
#    features remain active.
###############################################################################
resource "azurerm_security_center_subscription_pricing" "containers" {
  pricing_tier  = "Standard"
  resource_type = "Containers"
}

###############################################################################
# 6. Defender for Resource Manager
###############################################################################
resource "azurerm_security_center_subscription_pricing" "arm" {
  pricing_tier  = "Standard"
  resource_type = "Arm"
}

###############################################################################
# 7. Defender for App Services (CWPP – All)
###############################################################################
resource "azurerm_security_center_subscription_pricing" "app_services" {
  pricing_tier  = "Standard"
  resource_type = "AppServices"
}

###############################################################################
# 8. Defender for DNS (CWPP – All)
###############################################################################
resource "azurerm_security_center_subscription_pricing" "dns" {
  pricing_tier  = "Standard"
  resource_type = "Dns"
}

###############################################################################
# Security Policy: NIST SP 800-53 Rev. 5 at Subscription Scope
#
# Built-in policy set definition ID (Azure Government):
#   179d1daa-458f-4e47-8086-2a68d0d6c38f
#
# NOTE: This GUID is the Azure Government (AzureUSGovernment) built-in
# definition ID for NIST SP 800-53 Rev. 5.  The same GUID is also valid in
# Azure Commercial; both clouds share the same built-in policy definition IDs.
#
# Note: This assignment is in addition to any MG-level assignment; it ensures
# compliance reporting is visible directly within the subscription.
###############################################################################
resource "azurerm_subscription_policy_assignment" "nist_800_53_r5" {
  name                 = "nist-800-53-r5-sub"
  display_name         = "NIST SP 800-53 Rev. 5 – Subscription"
  subscription_id      = local.subscription_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
  location             = var.location
  enforce              = true

  # SystemAssigned identity required for DeployIfNotExists / Modify effects
  identity {
    type = "SystemAssigned"
  }
}

###############################################################################
# File Integrity Monitoring (FIM)
#
# Routes all Defender for Cloud security events (including FIM change data)
# to the centralized Log Analytics Workspace supplied via var.law_id.
#
# FIM monitors critical OS files, Windows Registry keys, and application
# files for unauthorized changes.  Data is streamed to the LAW for
# correlation with SIEM (e.g., Microsoft Sentinel).
###############################################################################

# Configure the subscription-level default workspace for Defender for Cloud.
# All agents deployed by Defender (MMA / AMA) will report to this workspace.
resource "azurerm_security_center_workspace" "fim" {
  scope        = local.subscription_scope
  workspace_id = var.law_id
}

# Enable auto-provisioning of the Log Analytics agent on VMs in this
# subscription.  This ensures all VMs stream security and FIM data to the
# centralized LAW without requiring per-VM configuration.
resource "azurerm_security_center_auto_provisioning" "log_analytics_agent" {
  auto_provision = "On"
}
