###############################################################################
# backend.tf – Deployment 2: Customer AVD Workload Landing Zone
#
# Each deployment (each vended subscription) has its own Terraform state.
# State is stored in Azure Government Blob Storage in the platform state
# storage account, under a customer-specific key prefix.
#
# All values are injected at `terraform init` time via GitLab CI/CD
# -backend-config flags – no secrets are hard-coded in source control.
###############################################################################

terraform {
  backend "azurerm" {
    # All values supplied at runtime via GitLab CI -backend-config flags:
    #   -backend-config="resource_group_name=<rg>"
    #   -backend-config="storage_account_name=<sa>"
    #   -backend-config="container_name=<container>"
    #   -backend-config="key=avd-workload/<subscription-name>/terraform.tfstate"
    #   -backend-config="environment=usgovernment"
    #
    # The storage account MUST reside in Azure Government.
    # One state file per vended subscription enforces clean blast-radius isolation.
  }
}
