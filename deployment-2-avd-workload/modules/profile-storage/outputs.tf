###############################################################################
# modules/profile-storage/outputs.tf
###############################################################################

output "storage_account_id" {
  description = "Resource ID of the FSLogix storage account."
  value       = azurerm_storage_account.fslogix.id
}

output "storage_account_name" {
  description = "Name of the FSLogix storage account."
  value       = azurerm_storage_account.fslogix.name
}

output "fslogix_share_name" {
  description = "Name of the FSLogix Azure Files share."
  value       = azurerm_storage_share.fslogix_profiles.name
}

output "fslogix_share_url" {
  description = "UNC path for the FSLogix share (Azure Government endpoint)."
  value       = "\\\\${azurerm_storage_account.fslogix.name}.file.core.usgovcloudapi.net\\${azurerm_storage_share.fslogix_profiles.name}"
}

output "private_endpoint_id" {
  description = "Resource ID of the Azure Files private endpoint."
  value       = azurerm_private_endpoint.fslogix.id
}
