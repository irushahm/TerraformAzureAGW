terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-01" {
  name     = "${var.prefix}-rg-01"
  location = "southeastasia"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "vnet-01" {
  name                = "${var.prefix}-rg-01-vnet-01"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = azurerm_resource_group.rg-01.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "vnet-02" {
  name                = "${var.prefix}-rg-01-vnet-02"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = azurerm_resource_group.rg-01.location
  address_space       = ["10.1.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "vnet-01-subnet-01" {
  name                 = "${var.prefix}-rg-01-vnet-01-subnet-01"
  resource_group_name  = azurerm_resource_group.rg-01.name
  virtual_network_name = azurerm_virtual_network.vnet-01.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "vnet-02-subnet-01" {
  name                 = "${var.prefix}-rg-01-vnet-02-subnet-01"
  resource_group_name  = azurerm_resource_group.rg-01.name
  virtual_network_name = azurerm_virtual_network.vnet-02.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_security_group" "nsg-01" {
  name                = "${var.prefix}-rg-01-nsg-01"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = azurerm_resource_group.rg-01.location

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "nsr" {
  name                        = "${var.prefix}-rg-01-nsr-01"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg-01.name
  network_security_group_name = azurerm_network_security_group.nsg-01.name
}

resource "azurerm_subnet_network_security_group_association" "snsga-01" {
  subnet_id                 = azurerm_subnet.vnet-01-subnet-01.id
  network_security_group_id = azurerm_network_security_group.nsg-01.id
}

resource "azurerm_subnet_network_security_group_association" "snsga-02" {
  subnet_id                 = azurerm_subnet.vnet-02-subnet-01.id
  network_security_group_id = azurerm_network_security_group.nsg-01.id
}

resource "azurerm_virtual_network_peering" "vnet-01-to-vnet-02" {
  name                         = "vnet-01-to-vnet-02"
  resource_group_name          = azurerm_resource_group.rg-01.name
  virtual_network_name         = azurerm_virtual_network.vnet-01.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-02.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnet-02-to-vnet-01" {
  name                         = "vnet-02-to-vnet-01"
  resource_group_name          = azurerm_resource_group.rg-01.name
  virtual_network_name         = azurerm_virtual_network.vnet-02.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-01.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}


resource "azurerm_public_ip" "pip-01" {
  name                = "${var.prefix}-rg-01-pip-01"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = azurerm_resource_group.rg-01.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "dev"
  }
}


resource "azurerm_network_interface" "vnic-01" {
  count               = var.vm_count
  name                = "${var.prefix}-rg-01-vnic-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = azurerm_resource_group.rg-01.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnet-01-subnet-01.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "vm-01" {
  count               = var.vm_count
  name                = "${var.prefix}-rg-01-vm-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = azurerm_resource_group.rg-01.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vnic-01[count.index].id,
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostname     = self.public_ip_address,
      user         = "adminuser",
      identityfile = "~/.ssh/id_rsa.pub"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["/bin/sh", "-c"]
  }

  tags = {
    environment = "dev"
  }
}


#Application Gateway configurations
resource "azurerm_application_gateway" "appgw1" {
  name                = "${var.prefix}-rg-01-appgw-01"
  resource_group_name = azurerm_resource_group.rg-01.name
  location            = azurerm_resource_group.rg-01.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw1-ip-configuration"
    subnet_id = azurerm_subnet.vnet-02-subnet-01.id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw1-ip-configuration"
    public_ip_address_id = azurerm_public_ip.pip-01.id
  }

  backend_address_pool {
    name         = "backendPool"
    ip_addresses = [azurerm_linux_virtual_machine.vm-01[0].private_ip_address, azurerm_linux_virtual_machine.vm-01[1].private_ip_address]

  }

  backend_http_settings {
    name                  = "httpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "appgw1-http-listener"
    frontend_ip_configuration_name = "appgw1-ip-configuration"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "appgw1-http-listener"
    backend_address_pool_name  = "backendPool"
    backend_http_settings_name = "httpSettings"
  }


}

data "azurerm_public_ip" "pip-01-data" {
  name                = azurerm_public_ip.pip-01.name
  resource_group_name = azurerm_resource_group.rg-01.name
}

output "public_ip_addresses" {
  value = "${data.azurerm_public_ip.pip-01-data.ip_address}"
}
