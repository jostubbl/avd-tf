###############################################################################
# modules/networking/main.tf – JUCE Networking Module
#
# Provisions:
#   - Spoke VNet with optional custom DNS servers
#   - VM subnet with associated NSG (deny inbound internet, allow required outbound)
#   - Private endpoint subnet (network policies disabled)
#   - Optional VNet peering to platform hub
###############################################################################

###############################################################################
# 1. Network Security Group for the VM subnet
###############################################################################
resource "azurerm_network_security_group" "vm" {
  name                = "nsg-${var.workload_name}-vm-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Deny all inbound traffic from the internet
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow inbound traffic from the virtual network (east-west)
  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer health probes
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Allow outbound to virtual network
  security_rule {
    name                       = "AllowVnetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow outbound to Azure Monitor / Log Analytics (for Defender FIM data)
  security_rule {
    name                       = "AllowAzureMonitorOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureMonitor"
  }

  # Deny all other outbound internet traffic
  security_rule {
    name                       = "DenyInternetOutbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

###############################################################################
# 2. Spoke Virtual Network
###############################################################################
resource "azurerm_virtual_network" "juce" {
  name                = "vnet-${var.workload_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  dns_servers         = length(var.dns_servers) > 0 ? var.dns_servers : null
  tags                = var.tags
}

###############################################################################
# 3. VM Subnet
###############################################################################
resource "azurerm_subnet" "vm" {
  name                 = "snet-${var.workload_name}-vm-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.juce.name
  address_prefixes     = [var.vm_subnet_address_prefix]
}

# Associate NSG with the VM subnet
resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

###############################################################################
# 4. Private Endpoint Subnet
#    Network policies disabled as required for private endpoints.
###############################################################################
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-${var.workload_name}-pe-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.juce.name
  address_prefixes     = [var.private_endpoint_subnet_address_prefix]

  private_endpoint_network_policies = "Disabled"
}

###############################################################################
# 5. VNet Peering to Hub (optional)
#    Enabled only when hub_vnet_id is provided.
###############################################################################
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.hub_vnet_id != "" ? 1 : 0

  name                      = "peer-${var.workload_name}-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.juce.name
  remote_virtual_network_id = var.hub_vnet_id

  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  allow_virtual_network_access = true
}
