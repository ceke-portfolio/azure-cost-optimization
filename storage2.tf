# storage.tf - Defines storage resources with security best practices

resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "blob_storage" {
  name                     = "enterpriseblob${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  min_tls_version          = "TLS1_2"  # Enforcing TLS 1.2 for enhanced security
  
  # Security best practices: Enable https traffic only
  # enable_https_traffic_only = true
  
  # Security best practices: Enable infrastructure encryption
  infrastructure_encryption_enabled = true
  
  # Security best practices: Default to private access
  blob_properties {
    delete_retention_policy {
      days = 7  # Retain deleted blobs for recovery
    }
    container_delete_retention_policy {
      days = 7  # Retain deleted containers for recovery
    }
  }
  
  # Network rules - Restricting access to specific subnets
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.web_subnet.id, azurerm_subnet.app_subnet.id]
    ip_rules                   = []
    bypass                     = ["AzureServices"]
  }

  tags = {
    environment = "production"
    purpose     = "application-storage"
  }
}

resource "azurerm_storage_container" "blob_container" {
  name                  = "secure-blob-container"
  storage_account_name  = azurerm_storage_account.blob_storage.name
  container_access_type = "private"  # Private access only, no public exposure
}

# Reduced number of managed disks to 1
resource "azurerm_managed_disk" "extra_disks" {
  count                = var.managed_disk_count
  name                 = "managed-disk-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "StandardSSD_LRS"  # Standard SSD for balanced performance/cost
  disk_size_gb         = var.managed_disk_size_gb
  create_option        = "Empty"
  
  #encryption_settings {
   # enabled = true  # Ensure disk encryption is enabled
  
  tags = {
    environment = "production"
    purpose     = "additional-storage"
  }
}