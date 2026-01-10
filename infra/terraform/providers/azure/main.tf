# Azure Provider Module for SendMyFiles

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name}-${var.random_suffix}"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "sendmyfiles-vnet-${var.random_suffix}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.web_subnet_address_prefix]
}

resource "azurerm_subnet" "sql" {
  name                 = "sql-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.sql_subnet_address_prefix]
}

resource "azurerm_subnet" "minio" {
  name                 = "minio-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.minio_subnet_address_prefix]
}

# Network Security Groups
resource "azurerm_network_security_group" "web" {
  name                = "web-nsg-${var.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWinRM"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "sql" {
  name                = "sql-nsg-${var.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowSQLFromWeb"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.web_subnet_address_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "minio" {
  name                = "minio-nsg-${var.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowMinIOAPIFromWeb"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = var.web_subnet_address_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMinIOConsoleFromWeb"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9001"
    source_address_prefix      = var.web_subnet_address_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "sql" {
  subnet_id                 = azurerm_subnet.sql.id
  network_security_group_id = azurerm_network_security_group.sql.id
}

resource "azurerm_subnet_network_security_group_association" "minio" {
  subnet_id                 = azurerm_subnet.minio.id
  network_security_group_id = azurerm_network_security_group.minio.id
}

# Public IPs
resource "azurerm_public_ip" "web" {
  name                = "web-pip-${var.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interfaces
resource "azurerm_network_interface" "web" {
  name                = "web-nic-${var.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

resource "azurerm_network_interface" "sql" {
  name                = "sql-nic-${var.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sql.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "minio" {
  name                = "minio-nic-${var.random_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.minio.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Web Server VM
resource "azurerm_windows_virtual_machine" "web" {
  name                = "sendmyfiles-web-${var.random_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.web_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.web.id]

  os_disk {
    name                 = "web-osdisk-${var.random_suffix}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.web_vm_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  winrm_listener {
    protocol = "Http"
  }
}

# SQL Server VM
resource "azurerm_windows_virtual_machine" "sql" {
  name                = "sendmyfiles-sql-${var.random_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.sql_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.sql.id]

  os_disk {
    name                 = "sql-osdisk-${var.random_suffix}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.sql_vm_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2022-WS2022"
    sku       = "SQLDEV"
    version   = "latest"
  }

  winrm_listener {
    protocol = "Http"
  }
}

# SQL Server Data Disk
resource "azurerm_managed_disk" "sql_data" {
  name                 = "sql-datadisk-${var.random_suffix}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.sql_data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "sql_data" {
  managed_disk_id    = azurerm_managed_disk.sql_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.sql.id
  lun                = "0"
  caching            = "ReadWrite"
}

# MinIO Server VM
resource "azurerm_windows_virtual_machine" "minio" {
  name                = "sendmyfiles-minio-${var.random_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.minio_vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.minio.id]

  os_disk {
    name                 = "minio-osdisk-${var.random_suffix}"
    caching            = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.minio_vm_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  winrm_listener {
    protocol = "Http"
  }
}

# MinIO Data Disk
resource "azurerm_managed_disk" "minio_data" {
  name                 = "minio-datadisk-${var.random_suffix}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.minio_data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "minio_data" {
  managed_disk_id    = azurerm_managed_disk.minio_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.minio.id
  lun                = "0"
  caching            = "ReadWrite"
}

