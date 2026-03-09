###############################################################################
# modules/msix-storage/outputs.tf
###############################################################################

output "storage_account_id" {
  description = "Resource ID of the MSIX storage account."
  value       = azurerm_storage_account.msix.id
}

output "storage_account_name" {
  description = "Name of the MSIX storage account."
  value       = azurerm_storage_account.msix.name
}

output "msix_share_name" {
  description = "Name of the MSIX packages Azure Files share."
  value       = azurerm_storage_share.msix_packages.name
}

output "msix_share_url" {
  description = "UNC path for the MSIX share (Azure Government storage endpoint)."
  value       = "\\\\${azurerm_storage_account.msix.name}.file.core.usgovcloudapi.net\\${azurerm_storage_share.msix_packages.name}"
}

output "msix_share_resource_manager_id" {
  description = "Resource ID of the MSIX storage account (used for RBAC scope)."
  value       = azurerm_storage_account.msix.id
}

output "private_endpoint_id" {
  description = "Resource ID of the MSIX Azure Files private endpoint."
  value       = azurerm_private_endpoint.msix.id
}
