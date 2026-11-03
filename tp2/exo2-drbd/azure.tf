resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.azure_location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_public_ip" "node" {
  name                = "${var.project_name}-azure-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_security_group" "node" {
  name                = "${var.project_name}-azure-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  security_rule {
    name                       = "ssh-admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.admin_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "drbd-from-aws"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.drbd_port)
    source_address_prefix      = "${aws_eip.node.public_ip}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "icmp-from-aws"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${aws_eip.node.public_ip}/32"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "node" {
  name                = "${var.project_name}-azure-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.node.id
  }
}

resource "azurerm_network_interface_security_group_association" "node" {
  network_interface_id      = azurerm_network_interface.node.id
  network_security_group_id = azurerm_network_security_group.node.id
}

resource "azurerm_linux_virtual_machine" "node" {
  name                            = "${var.project_name}-azure"
  computer_name                   = local.drbd_common.azure_name
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.azure_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.node.id]
  tags                            = local.common_tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # HDD standard : le moins cher
  }

  # Image officielle RESF (gratuite). Conditions à accepter une fois :
  # az vm image terms accept --publisher resf --offer rockylinux-x86_64 --plan 9-base
  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-base"
  }

  # Diagnostics de boot sur stockage managé : console série disponible
  # dans le portail sans compte de stockage à payer.
  boot_diagnostics {}

  custom_data = base64encode(templatefile("${path.module}/templates/drbd-node.sh.tftpl", merge(local.drbd_common, {
    node_name = local.drbd_common.azure_name
    public_ip = local.drbd_common.azure_ip
    role      = "secondary"
  })))
}

resource "azurerm_managed_disk" "data" {
  name                 = "${var.project_name}-azure-data"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = local.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_linux_virtual_machine.node.id
  lun                = 0
  caching            = "None"
}
