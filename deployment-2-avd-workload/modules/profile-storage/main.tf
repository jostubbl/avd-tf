###############################################################################
# modules/profile-storage/main.tf – FSLogix Profile Storage (Azure Files)
#
# Customer Cost:
#   - Storage account: ongoing capacity + transaction charges (customer-billable)
#   - Private endpoint NIC: no direct cost
#   - Private DNS A record: minimal cost
###############################################################################

locals {
  # Storage account names must be 3-24 chars, lowercase alphanumeric only
  # Truncate to ensure we stay within 24 chars
  sa_name = lower(substr(replace("st${var.workload_name}fslogix${var.environment}", "-", ""), 0, 24))
}

###############################################################################
# Storage Account – Premium Files (required for FSLogix performance SLA)
# Customer Cost: Premium Files tier pricing (per provisioned GB/month)
###############################################################################
resource "azurerm_storage_account" "fslogix" {
  name                            = local.sa_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Premium"
  account_replication_type        = var.storage_account_replication
  account_kind                    = "FileStorage"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true # Required for FSLogix SMB auth

  # Restrict public access – only accessible via private endpoint
  public_network_access_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = []
  }

  tags = var.tags
}

###############################################################################
# Azure Files Share – FSLogix User Profiles
# Customer Cost: Provisioned storage capacity (per GB/month)
###############################################################################
resource "azurerm_storage_share" "fslogix_profiles" {
  name               = "fslogix-profiles"
  storage_account_id = azurerm_storage_account.fslogix.id
  quota              = var.fslogix_share_size_gb
  enabled_protocol   = "SMB"
}

###############################################################################
# Private Endpoint – Azure Files
# Prevents storage traffic from traversing the public internet.
###############################################################################
data "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.usgovcloudapi.net"
  resource_group_name = var.private_dns_zone_resource_group
}

resource "azurerm_private_endpoint" "fslogix" {
  name                = "pe-${local.sa_name}-file"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${local.sa_name}-file"
    private_connection_resource_id = azurerm_storage_account.fslogix.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-${local.sa_name}-file"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.storage_file.id]
  }
}
