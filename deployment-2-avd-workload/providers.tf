###############################################################################
# providers.tf – Deployment 2: Customer AVD Workload Landing Zone
#
# Customer Responsibility: All resources deployed by this configuration are
# entirely customer-scoped and customer-billable.  This deployment runs inside
# the subscription vended by Deployment 1.
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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# ---------------------------------------------------------------------------
# Primary provider – runs inside the customer AVD workload subscription.
# Credentials are supplied via environment variables:
#   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
# ARM_SUBSCRIPTION_ID must be the subscription created by Deployment 1.
# ---------------------------------------------------------------------------
provider "azurerm" {
  environment                     = "usgovernment"
  resource_provider_registrations = "none"

  # The customer AVD workload subscription (output of Deployment 1).
  subscription_id = var.avd_subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }
}

provider "random" {}
