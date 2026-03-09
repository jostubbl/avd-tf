###############################################################################
# modules/msix-storage/main.tf – MSIX App Attach Storage (Azure Files)
#
# Customer Responsibility: All resources here are customer-scoped and
# customer-billable.  MSIX App Attach packages are stored on Azure Files
# Premium and mounted read-only by session hosts at logon.
#
# Customer Cost:
#   - Premium Azure Files storage: per provisioned GB/month
#   - Private endpoint NIC: no direct cost
#
# MSIX App Attach Flow:
#   1. Packages (.msix / .msixaab) are uploaded to the Azure Files share.
#   2. Session hosts mount the share (read-only) via FSLogix staging agent.
#   3. AVD host pool references the MSIX package URI for assignment to
#      Application Groups.  Configure via Azure portal or azurerm_virtual_
#      desktop_application resources after packages are uploaded.
###############################################################################

locals {
  # Storage account names must be 3-24 chars, lowercase alphanumeric only
  sa_name = lower(substr(replace("st${var.workload_name}msix${var.environment}", "-", ""), 0, 24))
}

###############################################################################
# Storage Account – Premium Files (MSIX App Attach requires fast I/O)
# Customer Cost: Premium Files tier pricing (per provisioned GB/month)
###############################################################################
resource "azurerm_storage_account" "msix" {
  name                            = local.sa_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Premium"
  account_replication_type        = var.storage_account_replication
  account_kind                    = "FileStorage"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  # Disable shared access keys; session hosts authenticate exclusively via
  # Azure AD managed identity (RBAC role assigned below).
  shared_access_key_enabled = false

  # All access via private endpoint only
  public_network_access_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = []
  }

  tags = var.tags
}

###############################################################################
# Azure Files Share – MSIX Packages
# Session hosts mount this share read-only for MSIX App Attach staging.
# Customer Cost: Per provisioned GB/month
###############################################################################
resource "azurerm_storage_share" "msix_packages" {
  name               = "msix-packages"
  storage_account_id = azurerm_storage_account.msix.id
  quota              = var.msix_share_size_gb
  enabled_protocol   = "SMB"
}

###############################################################################
# Private Endpoint – Azure Files (MSIX)
# Keeps MSIX package traffic on the private network.
###############################################################################
data "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.usgovcloudapi.net"
  resource_group_name = var.private_dns_zone_resource_group
}

resource "azurerm_private_endpoint" "msix" {
  name                = "pe-${local.sa_name}-file"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${local.sa_name}-file"
    private_connection_resource_id = azurerm_storage_account.msix.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-${local.sa_name}-file"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_file.id]
  }
}

###############################################################################
# RBAC – Session Host VMs → Storage File Data SMB Share Elevated Contributor
# This role allows the MSIX App Attach staging agent (running as SYSTEM) to
# mount the MSIX share and stage packages.  Read-only access is sufficient for
# users; Elevated Contributor is needed for the agent to create staging mount points.
###############################################################################
resource "azurerm_role_assignment" "session_host_msix" {
  for_each = toset(var.session_host_vm_principal_ids)

  # Scope to the storage account so that all current and future shares are covered.
  scope                = azurerm_storage_account.msix.id
  role_definition_name = "Storage File Data SMB Share Elevated Contributor"
  principal_id         = each.value
}
