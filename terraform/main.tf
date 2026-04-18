provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = "jd-rg"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "jd-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "jd-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "jd-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Fetch credentials from Key Vault
data "azurerm_key_vault" "kv" {
  name                = "jd-keyvault"
  resource_group_name = "jd-rg"
}

data "azurerm_key_vault_secret" "vm_user" {
  name         = "vm-username"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "vm_pass" {
  name         = "vm-password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "jd-vm"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = data.azurerm_key_vault_secret.vm_user.value
  admin_password      = data.azurerm_key_vault_secret.vm_pass.value
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}