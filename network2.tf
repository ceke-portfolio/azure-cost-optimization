# network.tf - Defines network configuration with security best practices

resource "azurerm_virtual_network" "vnet" {
  name                = "enterprise-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
  
  tags = {
    environment = "production"
  }
}

# Web Tier Subnet - Public-facing subnet for web servers
resource "azurerm_subnet" "web_subnet" {
  name                 = "web-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
  # Security best practice: Enable service endpoints for added security
  service_endpoints = ["Microsoft.Storage"]
}

# App Tier Subnet - Middle tier subnet for application servers
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
  # Security best practice: Enable service endpoints for added security
  service_endpoints = ["Microsoft.Storage"]
}

# Database Tier Subnet - Restricted subnet for database servers
resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Load Balancer for Web Tier
resource "azurerm_lb" "web_lb" {
  name                = "web-loadbalancer"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"  # Standard SKU for enhanced features

  frontend_ip_configuration {
    name                 = "web-frontend-ip"
    public_ip_address_id = azurerm_public_ip.web_lb_public_ip.id
  }
  
  tags = {
    environment = "production"
    tier        = "web"
  }
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "web_lb_public_ip" {
  name                = "web-lb-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"  # Static for production workloads
  sku                 = "Standard"  # Standard SKU required for Standard LB
  
  tags = {
    environment = "production"
    purpose     = "lb-frontend"
  }
}

# Load Balancer Backend Address Pool
resource "azurerm_lb_backend_address_pool" "web_backend_pool" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "web-backend-pool"
}

# Load Balancer Health Probe - Enhanced with proper protocol and path
resource "azurerm_lb_probe" "web_health_probe" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "web-health-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancer Rule
resource "azurerm_lb_rule" "web_lb_rule" {
  loadbalancer_id                = azurerm_lb.web_lb.id
  name                           = "web-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "web-frontend-ip"
  probe_id                       = azurerm_lb_probe.web_health_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_backend_pool.id]
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false
}

# NSG for Web Tier - Security best practices for web tier
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTP traffic
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow HTTPS traffic
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  
  # Allow Azure Load Balancer
  security_rule {
    name                       = "Allow-AzureLB"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic by default
  security_rule {
    name                       = "Deny-Inbound-Default"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = {
    environment = "production"
    tier        = "web"
  }
}

# NSG for App Tier - More restrictive, only allow traffic from web tier
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow traffic only from web subnet
  security_rule {
    name                       = "Allow-Web-Traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "8443"]
    source_address_prefix      = "10.0.1.0/24"  # Only from Web Subnet
    destination_address_prefix = "*"
  }

  # Deny direct internet access
  security_rule {
    name                       = "Deny-Direct-Internet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  
  tags = {
    environment = "production"
    tier        = "app"
  }
}

# NSG for Database Tier - Most restrictive, only allow traffic from app tier
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow database access only from app subnet
  security_rule {
    name                       = "Allow-App-DB-Access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"  # SQL Server port
    source_address_prefix      = "10.0.2.0/24"  # Only from App Subnet
    destination_address_prefix = "*"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = {
    environment = "production"
    tier        = "db"
  }
}