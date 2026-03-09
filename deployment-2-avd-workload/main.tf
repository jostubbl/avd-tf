###############################################################################
# main.tf – Deployment 2: Customer AVD Workload Landing Zone
#
# Customer Responsibility: Every resource in this file is deployed inside
# the customer AVD workload subscription and generates customer-billable costs.
#
# Platform Responsibility: None – this deployment assumes the following are
# already provided by the platform layer (management group policies):
#   - Hub networking / connectivity (peered via policy or manual peering)
#   - Azure Policy assignments (inherited from management group)
#   - Shared identity services (Entra ID, AD DS if applicable)
#   - Subscription budget (configured by Deployment 1)
###############################################################################

###############################################################################
# Data sources
###############################################################################

data "azurerm_client_config" "current" {}

###############################################################################
# Resource Groups
# Customer Cost: No direct cost – logical containers only.
# -----------------------------------------------------------------------------
# rg-networking  : Spoke VNet, NSGs, route tables
# rg-compute     : Session host VMs, availability sets
# rg-storage     : FSLogix storage account, private endpoints
# rg-avd         : AVD management plane (host pool, app group, workspace)
###############################################################################

resource "azurerm_resource_group" "networking" {
  name     = "rg-${var.workload_name}-networking-${var.environment}"
  location = var.location
  tags     = merge(var.tags, { cost_owner = "customer", resource_group = "networking" })
}

resource "azurerm_resource_group" "compute" {
  name     = "rg-${var.workload_name}-compute-${var.environment}"
  location = var.location
  tags     = merge(var.tags, { cost_owner = "customer", resource_group = "compute" })
}

resource "azurerm_resource_group" "storage" {
  name     = "rg-${var.workload_name}-storage-${var.environment}"
  location = var.location
  tags     = merge(var.tags, { cost_owner = "customer", resource_group = "storage" })
}

resource "azurerm_resource_group" "avd" {
  name     = "rg-${var.workload_name}-avd-${var.environment}"
  location = var.location
  tags     = merge(var.tags, { cost_owner = "customer", resource_group = "avd-management" })
}

###############################################################################
# Module: networking
# Customer Cost: VNet Gateway (if used), NAT Gateway, Private DNS zones.
# Standard VNets, NSGs, and route tables have no direct cost.
###############################################################################
module "networking" {
  source = "./modules/networking"

  resource_group_name          = azurerm_resource_group.networking.name
  location                     = var.location
  workload_name                = var.workload_name
  environment                  = var.environment
  vnet_address_space           = var.vnet_address_space
  session_host_subnet_cidr     = var.session_host_subnet_cidr
  private_endpoint_subnet_cidr = var.private_endpoint_subnet_cidr
  dns_servers                  = var.dns_servers
  hub_vnet_id                  = var.hub_vnet_id
  tags                         = var.tags

  depends_on = [azurerm_resource_group.networking]
}

###############################################################################
# Module: profile-storage
# Customer Cost: Azure Files storage (capacity + transactions) –
# this is a continuous, usage-based cost owned entirely by the customer.
###############################################################################
module "profile_storage" {
  source = "./modules/profile-storage"

  resource_group_name             = azurerm_resource_group.storage.name
  location                        = var.location
  workload_name                   = var.workload_name
  environment                     = var.environment
  fslogix_share_size_gb           = var.fslogix_share_size_gb
  storage_account_replication     = var.storage_account_replication
  private_endpoint_subnet_id      = module.networking.private_endpoint_subnet_id
  private_dns_zone_resource_group = azurerm_resource_group.networking.name
  tags                            = var.tags

  depends_on = [
    azurerm_resource_group.storage,
    module.networking,
  ]
}

###############################################################################
# Module: avd (AVD management plane using AVM modules)
# Customer Cost: No direct compute cost; session host VMs (see module below)
# are the primary cost driver.
###############################################################################
module "avd" {
  source = "./modules/avd"

  resource_group_name     = azurerm_resource_group.avd.name
  location                = var.location
  workload_name           = var.workload_name
  environment             = var.environment
  host_pool_name          = var.avd_host_pool_name
  host_pool_type          = var.avd_host_pool_type
  host_pool_load_balancer = var.avd_host_pool_load_balancer
  max_sessions_per_host   = var.avd_max_sessions_per_host
  workspace_name          = var.avd_workspace_name
  application_group_name  = var.avd_application_group_name
  avd_user_object_ids     = var.avd_user_object_ids
  tags                    = var.tags

  depends_on = [azurerm_resource_group.avd]
}

###############################################################################
# Module: session-hosts
# Customer Cost: VM compute (hourly), managed OS disks (monthly),
# and any associated networking egress – primary ongoing customer cost.
###############################################################################
module "session_hosts" {
  source = "./modules/session-hosts"

  resource_group_name          = azurerm_resource_group.compute.name
  location                     = var.location
  workload_name                = var.workload_name
  environment                  = var.environment
  session_host_count           = var.session_host_count
  vm_size                      = var.session_host_vm_size
  os_disk_type                 = var.session_host_os_disk_type
  image                        = var.session_host_image
  local_admin_username         = var.local_admin_username
  local_admin_password         = var.local_admin_password
  subnet_id                    = module.networking.session_host_subnet_id
  host_pool_registration_token = module.avd.host_pool_registration_token
  host_pool_name               = var.avd_host_pool_name
  domain_join_type             = var.domain_join_type
  domain_name                  = var.domain_name
  domain_join_username         = var.domain_join_username
  domain_join_password         = var.domain_join_password
  domain_ou_path               = var.domain_ou_path
  storage_account_name         = module.profile_storage.storage_account_name
  fslogix_share_name           = module.profile_storage.fslogix_share_name
  tags                         = var.tags

  depends_on = [
    azurerm_resource_group.compute,
    module.networking,
    module.avd,
    module.profile_storage,
  ]
}

###############################################################################
# RBAC – Session Host Administrators
# Grants the customer the ability to manage VMs and install applications.
# Customer Cost: No direct cost – IAM assignment only.
###############################################################################
resource "azurerm_role_assignment" "session_host_admin" {
  for_each = toset(var.session_host_admin_object_ids)

  scope                = azurerm_resource_group.compute.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = each.value
}

###############################################################################
# Module: msix-storage
# Customer Cost: Azure Files Premium (per provisioned GB/month) – customer-billable.
# MSIX App Attach packages are stored here and mounted read-only by session hosts.
###############################################################################
module "msix_storage" {
  source = "./modules/msix-storage"

  resource_group_name             = azurerm_resource_group.storage.name
  location                        = var.location
  workload_name                   = var.workload_name
  environment                     = var.environment
  msix_share_size_gb              = var.msix_share_size_gb
  storage_account_replication     = var.storage_account_replication
  private_endpoint_subnet_id      = module.networking.private_endpoint_subnet_id
  private_dns_zone_resource_group = azurerm_resource_group.networking.name
  session_host_vm_principal_ids   = module.session_hosts.vm_principal_ids
  tags                            = var.tags

  depends_on = [
    azurerm_resource_group.storage,
    module.networking,
    module.session_hosts,
  ]
}
