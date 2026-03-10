###############################################################################
# main.tf – Deployment 2: JUCE Customer VM Workload
#
# This deployment provisions JUCE workload resources into the subscription
# created and configured by Deployment 1.
#
# Resources deployed:
#   - Resource groups: networking and compute
#   - Module: networking (VNet, subnets, NSG, optional hub peering)
#   - Module: compute (VMs, NICs, availability set)
###############################################################################

locals {
  # Shared resource tags – all resources in this deployment receive these tags
  common_tags = {
    agency            = var.tag_agency
    program-office    = var.tag_program_office
    charge-site       = var.tag_charge_site
    project           = var.tag_project
    application-owner = var.tag_application_owner
    account           = var.tag_account
    environment       = var.environment
    workload          = var.workload_name
    managed-by        = "terraform"
  }
}

###############################################################################
# Resource Groups
#
# Naming convention: rg-{workload}-{component}-{environment}
###############################################################################

resource "azurerm_resource_group" "networking" {
  name     = "rg-${var.workload_name}-networking-${var.environment}"
  location = var.location
  tags     = merge(local.common_tags, { component = "networking" })
}

resource "azurerm_resource_group" "compute" {
  name     = "rg-${var.workload_name}-compute-${var.environment}"
  location = var.location
  tags     = merge(local.common_tags, { component = "compute" })
}

###############################################################################
# Module: networking
#   Provisions the spoke VNet, VM subnet, private endpoint subnet, and NSG
#   for JUCE virtual machines.  Optionally peers to the platform hub VNet.
###############################################################################
module "networking" {
  source = "./modules/networking"

  resource_group_name                    = azurerm_resource_group.networking.name
  location                               = var.location
  workload_name                          = var.workload_name
  environment                            = var.environment
  vnet_address_space                     = var.vnet_address_space
  vm_subnet_address_prefix               = var.vm_subnet_address_prefix
  private_endpoint_subnet_address_prefix = var.private_endpoint_subnet_address_prefix
  hub_vnet_id                            = var.hub_vnet_id
  dns_servers                            = var.dns_servers
  tags                                   = local.common_tags

  depends_on = [azurerm_resource_group.networking]
}

###############################################################################
# Module: compute
#   Provisions JUCE virtual machines, network interfaces, and availability set.
###############################################################################
module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.compute.name
  location            = var.location
  workload_name       = var.workload_name
  environment         = var.environment
  vm_count            = var.vm_count
  vm_size             = var.vm_size
  vm_os_disk_type     = var.vm_os_disk_type
  vm_image            = var.vm_image
  vm_subnet_id        = module.networking.vm_subnet_id
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  availability_zone   = var.availability_zone
  tags                = local.common_tags

  depends_on = [
    azurerm_resource_group.compute,
    module.networking,
  ]
}
