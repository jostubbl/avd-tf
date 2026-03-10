###############################################################################
# backend.tf – Deployment 1: JUCE Subscription + Baseline Configuration
#
# Terraform state is stored in Azure Government Blob Storage.
# All backend configuration values are injected at terraform init time via
# -backend-config flags from CI/CD variables.  No secrets are committed here.
#
# Example init command:
#   terraform init \
#     -backend-config="resource_group_name=<rg>" \
#     -backend-config="storage_account_name=<sa>" \
#     -backend-config="container_name=<container>" \
#     -backend-config="key=juce-subscription/terraform.tfstate"
###############################################################################

terraform {
  backend "azurerm" {
    environment = "usgovernment"
    # resource_group_name, storage_account_name, container_name, and key
    # are injected at terraform init via -backend-config flags.
  }
}
