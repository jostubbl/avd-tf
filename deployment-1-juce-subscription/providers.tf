###############################################################################
# providers.tf – Deployment 1: JUCE Subscription + Baseline Configuration
#
# Platform Responsibility: This deployment is executed by the central platform
# team and configures an Azure Government subscription with required Defender
# for Cloud plans, File Integrity Monitoring (FIM), and NIST SP 800-53 Rev. 5
# security policy.
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
# Management provider – runs in the billing / management subscription context
# to create or import the JUCE workload subscription.
# Credentials are supplied via environment variables:
#   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
# ARM_SUBSCRIPTION_ID must be the management/billing subscription.
# ---------------------------------------------------------------------------
provider "azurerm" {
  alias                           = "management"
  environment                     = "usgovernment"
  resource_provider_registrations = "none"

  features {}
}

# ---------------------------------------------------------------------------
# Workload provider – targets the JUCE workload subscription directly.
# Used for Defender for Cloud plans, FIM workspace, and policy assignments.
# Set TF_VAR_workload_subscription_id or pass -var="workload_subscription_id=<id>"
# after the subscription is created.
# ---------------------------------------------------------------------------
provider "azurerm" {
  environment                     = "usgovernment"
  resource_provider_registrations = "none"
  subscription_id                 = var.workload_subscription_id

  features {}
}
