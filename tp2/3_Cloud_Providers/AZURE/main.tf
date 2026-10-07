provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rocky-linux-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "rocky-linux-vnet"
  address_space        = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "rocky-linux-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "rocky-linux-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "azureuser"
  admin_password      = "Azure1234!@"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  os_disk {
    name              = "rocky-linux-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "openlogic"
    offer     = "rocky-linux"
    sku       = "9.3"
    version   = "latest"
  }

  data_disk {
    name              = "rocky-linux-data-disk-1"
    disk_size_gb      = 20
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  data_disk {
    name              = "rocky-linux-data-disk-2"
    disk_size_gb      = 20
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
