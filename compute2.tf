# compute.tf - Defines compute resources with security best practices

# Network Interfaces for Web Servers
resource "azurerm_network_interface" "web_nic" {
  count               = var.web_server_count
  name                = "web-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = {
    environment = "production"
    tier        = "web"
  }
}

# Associate NSG with web NICs
resource "azurerm_network_interface_security_group_association" "web_nic_nsg_association" {
  count                     = var.web_server_count
  network_interface_id      = azurerm_network_interface.web_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

# Associate Web Server NICs with Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "web_nic_lb_association" {
  count                   = var.web_server_count
  network_interface_id    = azurerm_network_interface.web_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_backend_pool.id
}

# Web Tier VMs
resource "azurerm_linux_virtual_machine" "web_servers" {
  count                 = var.web_server_count
  name                  = "web-server-${count.index}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.web_nic[count.index].id]
  size                  = var.web_server_size  # B2s (2 vCPUs)

  # Security best practice: Use managed disk for OS
  os_disk {
    name                 = "web-server-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"  # StandardSSD for better performance
    disk_size_gb         = 30
  }

  # Source Image Reference - Using recent Ubuntu LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  computer_name  = "web-server-${count.index}"
  admin_username = var.admin_username
  
  # Security best practice: Use key vault for secrets
  admin_password = data.azurerm_key_vault_secret.vm_password.value
  disable_password_authentication = false
  
  # Security best practice: Enable boot diagnostics
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.blob_storage.primary_blob_endpoint
  }
  
  tags = {
    environment = "production"
    tier        = "web"
  }
}

# App Tier Network Interfaces
resource "azurerm_network_interface" "app_nic" {
  count               = var.app_server_count
  name                = "app-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "app-ipconfig"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = {
    environment = "production"
    tier        = "app"
  }
}

# Associate NSG with app NICs
resource "azurerm_network_interface_security_group_association" "app_nic_nsg_association" {
  count                     = var.app_server_count
  network_interface_id      = azurerm_network_interface.app_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# App Tier VMs
resource "azurerm_linux_virtual_machine" "app_servers" {
  count                 = var.app_server_count
  name                  = "app-server-${count.index}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.app_nic[count.index].id]
  size                  = var.app_server_size  # B1s (1 vCPU)

  os_disk {
    name                 = "app-server-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  # Source Image Reference - Using recent Ubuntu LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  computer_name  = "app-server-${count.index}"
  admin_username = var.admin_username
  
  # Security best practice: Use key vault for secrets
  admin_password = data.azurerm_key_vault_secret.vm_password.value
  disable_password_authentication = false
  
  # Security best practice: Enable boot diagnostics
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.blob_storage.primary_blob_endpoint
  }
  
  tags = {
    environment = "production"
    tier        = "app"
  }
}

# Database Tier Network Interfaces
resource "azurerm_network_interface" "db_nic" {
  count               = var.db_server_count
  name                = "db-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "db-ipconfig"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = {
    environment = "production"
    tier        = "db"
  }
}

# Associate NSG with db NICs
resource "azurerm_network_interface_security_group_association" "db_nic_nsg_association" {
  count                     = var.db_server_count
  network_interface_id      = azurerm_network_interface.db_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# Database Tier VMs
resource "azurerm_linux_virtual_machine" "db_servers" {
  count                 = var.db_server_count
  name                  = "db-server-${count.index}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.db_nic[count.index].id]
  size                  = var.db_server_size  # B1ms (1 vCPU)

  os_disk {
    name                 = "db-server-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  # Source Image Reference - Using recent Ubuntu LTS
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  computer_name  = "db-server-${count.index}"
  admin_username = var.admin_username
  
  # Security best practice: Use key vault for secrets
  admin_password = data.azurerm_key_vault_secret.vm_password.value
  disable_password_authentication = false
  
  # Security best practice: Enable boot diagnostics
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.blob_storage.primary_blob_endpoint
  }
  
  tags = {
    environment = "production"
    tier        = "db"
  }
}