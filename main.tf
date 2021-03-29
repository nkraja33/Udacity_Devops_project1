provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}_RG"
  location = var.location
  tags = {
    Project = var.tag
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    Project = var.tag
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "webserver" {
  name                = "webservernsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "ssh"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
  }

  security_rule {
    access                     = "Deny"
    direction                  = "Inbound"
    name                       = "Internet_Access"
    priority                   = 101
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefix
  }
  tags = {
    Project = var.tag
  }
}

resource "azurerm_network_interface" "main" {
  count               = var.number_of_vms
  name                = "${var.prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Project = var.tag
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  tags = {
    Project = var.tag
  }
}

resource "azurerm_lb" "LB" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
  tags = {
    Project = var.tag
  }
}

resource "azurerm_lb_backend_address_pool" "lb_address_pool" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.LB.id
  name                = "accesspool"
}

resource "azurerm_lb_nat_rule" "lb_nat" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.LB.id
  name                           = "HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.LB.frontend_ip_configuration[0].name
}


resource "azurerm_network_interface_backend_address_pool_association" "lb_address_pool_association" {
  count                   = var.number_of_vms
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_address_pool.id
}

resource "azurerm_availability_set" "avail_set" {
  name                = "${var.prefix}-avail_set"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    Project = var.tag
  }
}


data "azurerm_image" "image" {
  name                = "packer-image_ubuntu"
  resource_group_name = "packer-image-rg"
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.number_of_vms
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  availability_set_id             = azurerm_availability_set.avail_set.id
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  source_image_id = data.azurerm_image.image.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  tags = {
    Project = var.tag
  }
}

resource "azurerm_managed_disk" "data" {
  count                = var.number_of_vms
  name                 = "${var.prefix}-disk-${count.index}"
  location             = azurerm_resource_group.rg.location
  create_option        = "Empty"
  disk_size_gb         = 10
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"

  tags = {
    Project = var.tag
  }

}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  virtual_machine_id = element(azurerm_linux_virtual_machine.main.*.id, count.index)
  managed_disk_id    = element(azurerm_managed_disk.data.*.id, count.index)
  lun                = 1
  caching            = "None"
  count              = var.number_of_vms
}
