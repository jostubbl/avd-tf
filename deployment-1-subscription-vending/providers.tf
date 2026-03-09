###############################################################################
# providers.tf – Deployment 1: Platform / Subscription Vending
#
# Platform Responsibility: This deployment is executed by the central platform
# team and runs in the context of the EA / MCA billing account owner.
#
# Cloud: AzureUSGovernment (FedRAMP High / DoD IL4-IL5 compatible)
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Primary provider – runs in the billing / root-tenant context to vend the
# subscription and perform management-group placement.
# Credentials are supplied via environment variables:
#   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
# ---------------------------------------------------------------------------
provider "azurerm" {
  environment                     = "usgovernment"
  resource_provider_registrations = "none"

  # The subscription used here is the "management" subscription that houses
  # the billing / EA scope.  The vended subscription is created as a *new*
  # resource rather than configured here.
  subscription_id = var.platform_subscription_id

  features {}
}
