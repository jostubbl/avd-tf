###############################################################################
# modules/compute/main.tf – JUCE Compute Module
#
# Provisions:
#   - Availability set (used when no availability zones are specified)
#   - Network Interface Cards (one per VM)
#   - Windows Server Virtual Machines
###############################################################################

###############################################################################
# 1. Availability Set
#    Created only when no availability zones are specified.  Provides fault
#    domain and update domain separation for VMs within a single datacenter.
###############################################################################
resource "azurerm_availability_set" "juce" {
  count = length(var.availability_zone) == 0 ? 1 : 0

  name                         = "avset-${var.workload_name}-${var.environment}"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = var.tags
}

###############################################################################
# 2. Network Interface Cards
#    One NIC per VM, attached to the JUCE VM subnet.
#    Private IP allocation is dynamic (Azure-assigned from the subnet CIDR).
###############################################################################
resource "azurerm_network_interface" "juce" {
  count = var.vm_count

  name                = "nic-${var.workload_name}-${var.environment}-${format("%02d", count.index + 1)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

###############################################################################
# 3. Virtual Machines
#    Windows Server VMs joined to the JUCE workload.
#    Naming convention: vm-{workload}-{environment}-{index}
###############################################################################
resource "azurerm_windows_virtual_machine" "juce" {
  count = var.vm_count

  name                = "vm-${var.workload_name}-${var.environment}-${format("%02d", count.index + 1)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  # Distribute across availability zones when specified, otherwise use availability set
  zone                = length(var.availability_zone) > 0 ? var.availability_zone[count.index % length(var.availability_zone)] : null
  availability_set_id = length(var.availability_zone) == 0 ? azurerm_availability_set.juce[0].id : null

  network_interface_ids = [
    azurerm_network_interface.juce[count.index].id,
  ]

  os_disk {
    name                 = "osdisk-${var.workload_name}-${var.environment}-${format("%02d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = var.vm_os_disk_type
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }

  # Enable VM encryption at host (Azure Government supported)
  encryption_at_host_enabled = true

  # Boot diagnostics use managed storage (no storage account required)
  boot_diagnostics {}

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_network_interface.juce]
}
