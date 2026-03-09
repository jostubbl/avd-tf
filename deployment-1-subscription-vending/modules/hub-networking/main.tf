###############################################################################
# modules/hub-networking/main.tf – Central Hub VNet, Azure Firewall, Gateways
#
# Platform Responsibility: All resources here are owned by the platform team
# and are NOT customer-billable.  They provide shared connectivity services
# for all workload subscriptions.
#
# Cost Attribution: Platform / shared services budget.
#   - Azure Firewall: hourly deployment + data-processing fee
#   - VPN Gateway (optional): hourly + data fee
#   - Azure Bastion (optional): hourly + session fee
#   - Public IPs: static allocation fee
###############################################################################

locals {
  name_prefix = "${var.workload_name}-hub"
}

###############################################################################
# Hub Virtual Network
###############################################################################
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.hub_vnet_address_space
  tags                = var.tags
}

###############################################################################
# Subnets (names are fixed by Azure requirements)
###############################################################################

# Azure Firewall requires a subnet named exactly "AzureFirewallSubnet" (min /26)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_cidr]
}

# VPN / ExpressRoute Gateway requires a subnet named exactly "GatewaySubnet" (min /27)
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

# Azure Bastion requires a subnet named exactly "AzureBastionSubnet" (min /26)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

# Identity subnet: used by AADDS or AD DS VMs.
# AADDS automatically delegates this subnet to Microsoft.AAD/domainServices
# at service deployment time; explicit Terraform delegation configuration is
# not required here.
resource "azurerm_subnet" "identity" {
  name                 = "IdentitySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.identity_subnet_cidr]
}

# Management subnet: jump hosts, monitoring agents, network management tools
resource "azurerm_subnet" "management" {
  name                 = "ManagementSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.management_subnet_cidr]
}

###############################################################################
# Azure Firewall Policy
# Centralises rule management; policies can be linked to child policies.
###############################################################################
resource "azurerm_firewall_policy" "hub" {
  name                = "afwp-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.firewall_sku_tier

  threat_intelligence_mode = var.firewall_threat_intel_mode

  # DNS proxy enables the firewall to resolve FQDNs in network rules.
  # Session hosts and Azure services will use the firewall as DNS forwarder.
  dns {
    proxy_enabled = true
  }

  tags = var.tags
}

###############################################################################
# Azure Firewall – Standard/Premium tier
# Platform Cost: ~$1.25/hour + $0.016/GB data processed
###############################################################################
resource "azurerm_public_ip" "firewall" {
  name                = "pip-${local.name_prefix}-afw"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall" "hub" {
  name                = "afw-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  zones               = ["1", "2", "3"]
  tags                = var.tags

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

###############################################################################
# Firewall Policy Rule Collection Group – Baseline AVD Rules
# Allows required outbound traffic for AVD session hosts via the firewall.
###############################################################################
resource "azurerm_firewall_policy_rule_collection_group" "avd_baseline" {
  name               = "rcg-avd-baseline"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  # Application rule collection: FQDN-based outbound rules
  application_rule_collection {
    name     = "arc-avd-required"
    priority = 100
    action   = "Allow"

    # Required AVD control-plane FQDNs (Azure Government endpoints)
    rule {
      name             = "AVD-ControlPlane-Gov"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.wvd.microsoft.us",
        "gcs.prod.monitoring.core.usgovcloudapi.net",
        "production.diagnostics.monitoring.core.usgovcloudapi.net",
        "catalogartifact.azureedge.net",
        "*.events.data.microsoft.com",
      ]
      protocols {
        port = 443
        type = "Https"
      }
    }

    # Azure Monitor / Log Analytics (Azure Government)
    rule {
      name             = "AzureMonitor-Gov"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.ods.opinsights.azure.us",
        "*.oms.opinsights.azure.us",
        "*.azure-automation.us",
      ]
      protocols {
        port = 443
        type = "Https"
      }
    }

    # Windows Update (Azure Government routing)
    rule {
      name             = "WindowsUpdate"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "*.delivery.mp.microsoft.com",
      ]
      protocols {
        port = 443
        type = "Https"
      }
    }

    # Azure Storage (for AVD agent downloads and FSLogix)
    rule {
      name             = "AzureStorage-Gov"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.blob.core.usgovcloudapi.net",
        "*.file.core.usgovcloudapi.net",
      ]
      protocols {
        port = 443
        type = "Https"
      }
    }
  }
}

###############################################################################
# Route Table for Spoke Subnets
# Spokes should associate their session-host route table with this to force
# traffic through the hub firewall.
###############################################################################
resource "azurerm_route_table" "spoke_default" {
  name                          = "rt-${local.name_prefix}-spoke-default"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  route {
    name                   = "DefaultToFirewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

###############################################################################
# VPN Gateway (optional)
# Platform Cost: ~$0.19–$1.40/hour depending on SKU
###############################################################################
resource "azurerm_public_ip" "vpn_gateway" {
  count = var.deploy_vpn_gateway ? 1 : 0

  name                = "pip-${local.name_prefix}-vpngw"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.deploy_vpn_gateway ? 1 : 0

  name                = "vpngw-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vpn_gateway_sku
  generation          = "Generation2"
  active_active       = false
  bgp_enabled         = false
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

###############################################################################
# Azure Bastion (optional)
# Platform Cost: ~$0.19/hour + $0.025/GB data processed
###############################################################################
resource "azurerm_public_ip" "bastion" {
  count = var.deploy_bastion ? 1 : 0

  name                = "pip-${local.name_prefix}-bastion"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_bastion_host" "hub" {
  count = var.deploy_bastion ? 1 : 0

  name                = "bas-${local.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.bastion_sku
  tags                = var.tags

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}
