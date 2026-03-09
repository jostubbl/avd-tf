###############################################################################
# modules/networking/main.tf – Spoke VNet, Subnets, NSGs, Route Tables
#
# Customer Cost:
#   - VNet, subnets, NSGs, route tables: NO direct cost
#   - VNet peering (if hub_vnet_id provided): minimal peering data cost
#   - Private DNS zones: minimal monthly cost ($0.50/zone)
###############################################################################

locals {
  name_prefix = "${var.workload_name}-${var.environment}"
}

###############################################################################
# Spoke Virtual Network
###############################################################################
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${local.name_prefix}-spoke"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  dns_servers         = length(var.dns_servers) > 0 ? var.dns_servers : null
  tags                = var.tags
}

###############################################################################
# NSG – AVD Session Hosts
# Allows required AVD control-plane traffic; blocks direct RDP from internet.
###############################################################################
resource "azurerm_network_security_group" "session_hosts" {
  name                = "nsg-${local.name_prefix}-sessionhosts"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Allow required AVD gateway outbound (HTTPS)
  security_rule {
    name                       = "Allow-AVD-Gateway-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "WindowsVirtualDesktop"
  }

  # Allow Azure Monitor / Log Analytics outbound
  security_rule {
    name                       = "Allow-AzureMonitor-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMonitor"
  }

  # Allow SMB to private endpoint subnet for FSLogix (Azure Files)
  security_rule {
    name                       = "Allow-SMB-FSLogix-Outbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = var.session_host_subnet_cidr
    destination_address_prefix = var.private_endpoint_subnet_cidr
  }

  # Allow inbound from VNet (session host ↔ session host, management)
  security_rule {
    name                       = "Allow-VNet-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer health probes inbound
  security_rule {
    name                       = "Allow-AzureLB-Inbound"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny all other inbound internet traffic (AVD reverse-connect only)
  security_rule {
    name                       = "Deny-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

###############################################################################
# NSG – Private Endpoints
###############################################################################
resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-${local.name_prefix}-privateendpoints"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Allow SMB inbound from session host subnet (FSLogix)
  security_rule {
    name                       = "Allow-SMB-From-SessionHosts"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = var.session_host_subnet_cidr
    destination_address_prefix = "*"
  }

  # Allow HTTPS inbound from session host subnet (Key Vault, Blob)
  security_rule {
    name                       = "Allow-HTTPS-From-SessionHosts"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.session_host_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

###############################################################################
# Route Table – Session Hosts
# Forces traffic through hub NVA/firewall (if applicable).
# In hub-spoke topology the platform firewall IP is injected as next-hop.
###############################################################################
resource "azurerm_route_table" "session_hosts" {
  name                          = "rt-${local.name_prefix}-sessionhosts"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  # Default route to Azure Internet (replace next_hop_ip with NVA IP if hub exists)
  route {
    name           = "DefaultRoute"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

###############################################################################
# Subnet – AVD Session Hosts
###############################################################################
resource "azurerm_subnet" "session_hosts" {
  name                 = "snet-${local.name_prefix}-sessionhosts"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.session_host_subnet_cidr]
}

resource "azurerm_subnet_network_security_group_association" "session_hosts" {
  subnet_id                 = azurerm_subnet.session_hosts.id
  network_security_group_id = azurerm_network_security_group.session_hosts.id
}

resource "azurerm_subnet_route_table_association" "session_hosts" {
  subnet_id      = azurerm_subnet.session_hosts.id
  route_table_id = azurerm_route_table.session_hosts.id
}

###############################################################################
# Subnet – Private Endpoints
# private_endpoint_network_policies must be Disabled for private endpoints.
###############################################################################
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-${local.name_prefix}-privateendpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.private_endpoint_subnet_cidr]

  # Disable network policies for private endpoint subnet
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

###############################################################################
# Private DNS Zones – required for private endpoint name resolution
# Customer Cost: ~$0.50/zone/month + query charges.
###############################################################################

resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.usgovcloudapi.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_file" {
  name                  = "link-${local.name_prefix}-storage-file"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = var.tags
}

###############################################################################
# VNet Peering to Hub (optional – only when hub_vnet_id is provided)
# Customer Cost: VNet peering data transfer charges if applicable.
###############################################################################
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.hub_vnet_id != "" ? 1 : 0

  name                         = "peer-${local.name_prefix}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
