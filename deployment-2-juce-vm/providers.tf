###############################################################################
# providers.tf – Deployment 2: JUCE Customer VM Workload
#
# Customer Responsibility: All resources deployed by this configuration are
# customer-scoped and customer-billable.  This deployment runs inside the
# subscription configured by Deployment 1.
#
# Cloud: AzureUSGovernment
# Region: usgovarizona (required for all JUCE deployments)
#
# Provider note: The azurerm provider uses resource_provider_registrations =
# "none" which is the azurerm 4.x equivalent of skip_provider_registration =
# true, as required by the JUCE specification.
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
# Primary provider – runs inside the JUCE workload subscription.
# Credentials are supplied via environment variables:
#   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
# ARM_SUBSCRIPTION_ID must match the subscription created by Deployment 1.
# ---------------------------------------------------------------------------
provider "azurerm" {
  environment                     = "usgovernment"
  resource_provider_registrations = "none"

  # The JUCE workload subscription (output of Deployment 1).
  subscription_id = var.subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }
}
