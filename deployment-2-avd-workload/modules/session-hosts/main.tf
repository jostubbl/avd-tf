###############################################################################
# modules/session-hosts/main.tf – AVD Session Host VMs
#
# Customer Cost:
#   - VM compute: primary ongoing cost (per-second billing while running)
#   - Managed OS disks: monthly per-GB cost
#   - NIC: no direct cost
#   - VM extensions: no direct cost
#
# All resources here are customer-scoped and customer-billable.
###############################################################################

locals {
  name_prefix = "${var.workload_name}-${var.environment}"

  # FSLogix UNC path using Azure Government storage endpoint
  fslogix_vhd_location = "\\\\${var.storage_account_name}.file.core.usgovcloudapi.net\\${var.fslogix_share_name}"
}

###############################################################################
# Availability Set
# Spreads VMs across fault/update domains for availability.
# Customer Cost: No direct cost (Availability Set is free).
###############################################################################
resource "azurerm_availability_set" "session_hosts" {
  name                         = "avail-${local.name_prefix}-sessionhosts"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = var.tags
}

###############################################################################
# Network Interface Cards
# Customer Cost: No direct NIC cost.
###############################################################################
resource "azurerm_network_interface" "session_host" {
  count = var.session_host_count

  name                = "nic-${local.name_prefix}-sh-${format("%02d", count.index + 1)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

###############################################################################
# Session Host Virtual Machines
# Customer Cost: VM compute charges (per second) + managed disk (per month).
###############################################################################
resource "azurerm_windows_virtual_machine" "session_host" {
  count = var.session_host_count

  name                = "vm-${local.name_prefix}-sh-${format("%02d", count.index + 1)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.local_admin_username
  admin_password      = var.local_admin_password
  availability_set_id = azurerm_availability_set.session_hosts.id

  network_interface_ids = [
    azurerm_network_interface.session_host[count.index].id,
  ]

  os_disk {
    name                 = "osdisk-${local.name_prefix}-sh-${format("%02d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  # Enable AAD / Entra ID login extension to be installed below
  identity {
    type = "SystemAssigned"
  }

  # Required for AVD FSLogix + RDP Shortpath
  timezone = "Eastern Standard Time"

  tags = merge(var.tags, { session_host_index = tostring(count.index + 1) })
}

###############################################################################
# VM Extension – AAD Login (Azure AD / Entra ID join)
# Only installed when domain_join_type = "AAD"
###############################################################################
resource "azurerm_virtual_machine_extension" "aad_login" {
  count = var.domain_join_type == "AAD" ? var.session_host_count : 0

  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    mdmId = ""
  })

  tags = var.tags
}

###############################################################################
# VM Extension – Domain Join (ADDS)
# Only installed when domain_join_type = "ADDS"
###############################################################################
resource "azurerm_virtual_machine_extension" "domain_join" {
  count = var.domain_join_type == "ADDS" ? var.session_host_count : 0

  name                       = "DomainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = var.domain_ou_path
    User    = var.domain_join_username
    Restart = true
    Options = 3
  })

  protected_settings = jsonencode({
    Password = var.domain_join_password
  })

  tags = var.tags

  depends_on = [azurerm_windows_virtual_machine.session_host]
}

###############################################################################
# VM Extension – AVD Agent (DSC)
# Installs and registers the AVD agent, connecting the VM to the host pool.
###############################################################################
resource "azurerm_virtual_machine_extension" "avd_dsc" {
  count = var.session_host_count

  name                       = "AVDDSCAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    modulesUrl            = var.avd_dsc_configuration_url
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      HostPoolName                           = var.host_pool_name
      RegistrationInfoToken                  = var.host_pool_registration_token
      AadJoin                                = var.domain_join_type == "AAD"
      SessionHostConfigurationLastUpdateTime = ""
    }
  })

  tags = var.tags

  # Must run after domain join (if ADDS) or AAD join extension
  depends_on = [
    azurerm_virtual_machine_extension.aad_login,
    azurerm_virtual_machine_extension.domain_join,
  ]
}

###############################################################################
# VM Extension – FSLogix Configuration
# Configures FSLogix profile containers via PowerShell DSC / Custom Script.
# Sets the VHD location to the Azure Files private endpoint.
###############################################################################
resource "azurerm_virtual_machine_extension" "fslogix_config" {
  count = var.session_host_count

  name                       = "FSLogixConfiguration"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = join(" ", [
      "powershell.exe -ExecutionPolicy Bypass -Command",
      "\"",
      # Enable FSLogix
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'Enabled' -Value 1 -Type DWord -Force;",
      # Set VHD location to Azure Files share
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'VHDLocations' -Value '${local.fslogix_vhd_location}' -Type String -Force;",
      # Configure container type (0 = VHD, 3 = VHDX)
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'VolumeType' -Value 'VHDX' -Type String -Force;",
      # Enable Delete local profile when FSLogix profile loads
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'DeleteLocalProfileWhenVHDShouldApply' -Value 1 -Type DWord -Force;",
      "\""
    ])
  })

  tags = var.tags

  depends_on = [azurerm_virtual_machine_extension.avd_dsc]
}
