###############################################################################
# modules/identity/outputs.tf
###############################################################################

output "aadds_id" {
  description = "Resource ID of the AADDS instance (empty string if not deployed)."
  value       = var.deploy_aadds ? azurerm_active_directory_domain_service.aadds[0].id : ""
}

output "domain_controller_ip_addresses" {
  description = <<-EOT
    IP addresses of the AADDS domain controllers.
    Pass these as dns_servers in the D2 spoke VNet to enable domain-aware name resolution.
    Empty list if AADDS is not deployed.
  EOT
  value       = var.deploy_aadds ? azurerm_active_directory_domain_service.aadds[0].initial_replica_set[0].domain_controller_ip_addresses : []
}

output "domain_name" {
  description = "FQDN of the managed AADDS domain (empty string if not deployed)."
  value       = var.deploy_aadds ? azurerm_active_directory_domain_service.aadds[0].domain_name : ""
}
