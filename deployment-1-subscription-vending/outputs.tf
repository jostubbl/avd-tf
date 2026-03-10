###############################################################################
# outputs.tf – Deployment 1: Platform / Subscription Vending
#
# These outputs are consumed by Deployment 2 (AVD workload) via remote state
# or passed as pipeline variables in GitLab CI/CD.
###############################################################################

# ---------------------------------------------------------------------------
# Subscription
# ---------------------------------------------------------------------------

output "subscription_id" {
  description = "The UUID of the newly vended AVD workload subscription."
  value       = azurerm_subscription.avd_workload.subscription_id
}

output "subscription_resource_id" {
  description = "The full ARM resource ID of the vended subscription."
  value       = azurerm_subscription.avd_workload.id
}

output "tenant_id" {
  description = "The Azure AD tenant ID associated with the subscription."
  value       = azurerm_subscription.avd_workload.tenant_id
}

output "management_group_id" {
  description = "The ID of the ALZ management group the subscription was placed into."
  value       = var.management_group_id
}

output "subscription_name" {
  description = "Display name of the vended subscription."
  value       = azurerm_subscription.avd_workload.subscription_name
}

output "monthly_budget_id" {
  description = "Resource ID of the monthly consumption budget."
  value       = azurerm_consumption_budget_subscription.monthly.id
}

# ---------------------------------------------------------------------------
# Hub Networking (only populated when deploy_hub_networking = true)
# ---------------------------------------------------------------------------

output "hub_vnet_id" {
  description = "Resource ID of the hub VNet (pass to D2 as hub_vnet_id for spoke peering). Empty string when deploy_hub_networking = false."
  value       = var.deploy_hub_networking ? module.hub_networking[0].hub_vnet_id : ""
}

output "hub_vnet_name" {
  description = "Name of the hub VNet. Empty string when deploy_hub_networking = false."
  value       = var.deploy_hub_networking ? module.hub_networking[0].hub_vnet_name : ""
}

output "firewall_private_ip" {
  description = "Private IP of the hub firewall (use as next-hop in D2 spoke route table). Empty string when deploy_hub_networking = false."
  value       = var.deploy_hub_networking ? module.hub_networking[0].firewall_private_ip : ""
}

output "spoke_route_table_id" {
  description = "Resource ID of the default spoke route table. Empty string when deploy_hub_networking = false."
  value       = var.deploy_hub_networking ? module.hub_networking[0].spoke_route_table_id : ""
}

output "vpn_gateway_public_ip" {
  description = "Public IP of the VPN Gateway. Empty string if not deployed."
  value       = var.deploy_hub_networking ? module.hub_networking[0].vpn_gateway_public_ip : ""
}

# ---------------------------------------------------------------------------
# Identity (only populated when deploy_hub_networking = true)
# ---------------------------------------------------------------------------

output "domain_controller_ip_addresses" {
  description = <<-EOT
    IP addresses of AADDS domain controllers.
    Pass these as dns_servers in D2 to enable domain-joined session hosts.
    Empty list if AADDS / hub networking is not deployed.
  EOT
  value       = var.deploy_hub_networking ? module.identity[0].domain_controller_ip_addresses : []
}

output "aadds_domain_name" {
  description = "FQDN of the AADDS managed domain. Empty string if not deployed."
  value       = var.deploy_hub_networking ? module.identity[0].domain_name : ""
}

# ---------------------------------------------------------------------------
# Policy (MG scope)
# ---------------------------------------------------------------------------

output "fedramp_high_assignment_id" {
  description = "Resource ID of the FedRAMP High policy assignment."
  value       = module.policy.fedramp_high_assignment_id
}

output "nist_800_53_r5_assignment_id" {
  description = "Resource ID of the NIST SP 800-53 Rev 5 policy assignment at MG scope."
  value       = module.policy.nist_800_53_r5_assignment_id
}

# ---------------------------------------------------------------------------
# Defender for Cloud
# ---------------------------------------------------------------------------

output "nist_800_53_r5_subscription_assignment_id" {
  description = "Resource ID of the NIST SP 800-53 Rev. 5 policy assignment at subscription scope."
  value       = module.defender.nist_800_53_r5_subscription_assignment_id
}

output "fim_workspace_id" {
  description = "The Log Analytics Workspace ID configured for FIM / Defender for Cloud data collection."
  value       = module.defender.fim_workspace_id
}

