###############################################################################
# backend.tf – Deployment 1: Platform / Subscription Vending
#
# State is stored in Azure Government Blob Storage.
# All sensitive values are injected via GitLab CI/CD environment variables
# at `terraform init` time with the -backend-config flag so that no secrets
# are hard-coded in source control.
#
# GitLab CI passes:
#   TF_VAR_backend_resource_group_name
#   TF_VAR_backend_storage_account_name
#   TF_VAR_backend_container_name
# or via -backend-config="key=value" flags during init.
###############################################################################

terraform {
  backend "azurerm" {
    # All values supplied at runtime via GitLab CI -backend-config flags:
    #   -backend-config="resource_group_name=<rg>"
    #   -backend-config="storage_account_name=<sa>"
    #   -backend-config="container_name=<container>"
    #   -backend-config="key=subscription-vending/terraform.tfstate"
    #   -backend-config="environment=usgovernment"
    #
    # The storage account MUST reside in Azure Government.
  }
}
