###############################################################################
# modules/identity/main.tf – Azure AD Domain Services (AADDS)
#
# Platform Responsibility: AADDS is a shared managed domain service owned by
# the platform team.  All workload subscriptions' session hosts join this domain.
#
# Cost Attribution: Platform / shared services budget.
#   - AADDS Standard: ~$0.17/hour (~$122/month)
#   - AADDS Enterprise / Premium: higher tiers for more objects / features
#
# Prerequisites (must be met before enabling deploy_aadds = true):
#   1. Azure AD tenant must have Azure AD Premium P1 or P2 licenses
#   2. The service principal running Terraform needs Global Administrator
#      or Application Administrator rights in Azure AD to enable AADDS
#   3. The "Microsoft.AAD" resource provider must be registered in the
#      subscription (handled automatically unless resource_provider_registrations = "none")
#   4. The identity subnet must be delegated to Microsoft.AAD/domainServices
#      (already done in the hub-networking module's IdentitySubnet)
###############################################################################

###############################################################################
# Azure AD Domain Services (conditional)
###############################################################################
resource "azurerm_active_directory_domain_service" "aadds" {
  count = var.deploy_aadds ? 1 : 0

  # Name derived from the first DNS label to stay well under the 64-char limit
  name                = "aadds-${split(".", var.aadds_domain_name)[0]}"
  location            = var.location
  resource_group_name = var.resource_group_name

  domain_name = var.aadds_domain_name
  sku         = var.aadds_sku

  # Secure LDAP (LDAPS): omitted here to avoid requiring a PFX certificate at
  # initial deployment.  Enable LDAPS post-deployment via the Azure portal or
  # by adding a secure_ldap block with pfx_certificate from your PKI/Key Vault.

  filtered_sync_enabled = false

  notifications {
    additional_recipients = var.aadds_notification_emails
    notify_dc_admins      = true
    notify_global_admins  = true
  }

  initial_replica_set {
    subnet_id = var.identity_subnet_id
  }

  # AADDS requires the tenant to have specific security settings.
  # These are the recommended security settings for FedRAMP High / IL4-IL5.
  security {
    sync_kerberos_passwords = true
    sync_ntlm_passwords     = true
    sync_on_prem_passwords  = true

    # Disable legacy authentication protocols per FedRAMP control IA-2(12)
    # and NIST SP 800-63B.  Applications relying on NTLMv1 or TLS 1.0/1.1
    # must be updated to use modern authentication before enabling AADDS.
    ntlm_v1_enabled = false
    tls_v1_enabled  = false
  }

  tags = var.tags
}
