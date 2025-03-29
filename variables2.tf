# variables.tf - Defines all input variables for the Terraform configuration

# Location and Resource Group Variables
variable "location" {
  description = "Azure Region for Deployment"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Azure Resource Group Name"
  type        = string
}

# Authentication Variables
variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
  
  validation {
    condition     = length(var.admin_username) >= 1 && length(var.admin_username) <= 64
    error_message = "Admin username must be between 1 and 64 characters long."
  }
}

# Scaling Variables 
variable "web_server_count" {
  description = "Number of web servers to deploy"
  type        = number
  default     = 2  # Reduced from 50 to 2
  
  validation {
    condition     = var.web_server_count >= 1 && var.web_server_count <= 10
    error_message = "Web server count must be between 1 and 10."
  }
}

variable "app_server_count" {
  description = "Number of application servers to deploy"
  type        = number
  default     = 1  # Reduced from 30 to 1
  
  validation {
    condition     = var.app_server_count >= 1 && var.app_server_count <= 5
    error_message = "Application server count must be between 1 and 5."
  }
}

variable "db_server_count" {
  description = "Number of database servers to deploy"
  type        = number
  default     = 1  # Reduced from 10 to 1
  
  validation {
    condition     = var.db_server_count >= 1 && var.db_server_count <= 3
    error_message = "Database server count must be between 1 and 3."
  }
}

# VM Size Variables - Updated to use cheaper B-series VMs
variable "web_server_size" {
  description = "VM size for web servers"
  type        = string
  default     = "Standard_B2s"  # Changed from D16s_v3 to B2s (2 vCPUs, ~$0.0416/hour)
}

variable "app_server_size" {
  description = "VM size for application servers"
  type        = string
  default     = "Standard_B1s"  # Changed from D16s_v3 to B1s (1 vCPU, ~$0.0104/hour)
}

variable "db_server_size" {
  description = "VM size for database servers"
  type        = string
  default     = "Standard_B1ms"  # Changed from D8s_v3 to B1ms (1 vCPU, ~$0.0208/hour)
}

# Storage Variables
variable "storage_account_tier" {
  description = "Storage Account Tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage Replication Type"
  type        = string
  default     = "LRS"  # Locally Redundant Storage for cost optimization
}

variable "managed_disk_count" {
  description = "Number of managed disks to create"
  type        = number
  default     = 1  # Reduced from 10 to 1
}

variable "managed_disk_size_gb" {
  description = "Size of each managed disk in GB"
  type        = number
  default     = 32  # Reduced from 1024 to 32
}