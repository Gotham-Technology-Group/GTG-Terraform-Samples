# =============================================================================
# TERRAFORM BACKEND VARIABLES
# =============================================================================

variable "backend_resource_group_name" {
  description = "Name of the resource group containing the Terraform state storage account"
  type        = string
  default     = "rg-terraform-state"
}

variable "backend_storage_account_name" {
  description = "Name of the storage account to store the Terraform state"
  type        = string
  default     = "aztfstatestorageacct"
}

variable "backend_container_name" {
  description = "Name of the storage container to store the Terraform state"
  type        = string
  default     = "tfstate"
}

variable "backend_key" {
  description = "Name of the Terraform state file"
  type        = string
  default     = "windowsvmmodule.tfstate"
}

variable "subscription_id" {
  description = "Azure subscription ID where resources will be deployed"
  type        = string
  default     = "0000-9c42-4514-a48d-d822017f000"
  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid GUID format."
  }
}

# =============================================================================
# GENERAL CONFIGURATION VARIABLES
# =============================================================================

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default =     "East US"
  validation {
    condition = contains([
      "East US", "West US"
    ], var.location)
    error_message = "Location must be in East US or West US per policy"
  }
}

variable "rg_name" {
  description = "Name of the new resource group where the VM will be deployed"
  type        = string
  default     = "rg-vm-demo"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._\\-()]+$", var.rg_name))
    error_message = "Resource group name must contain only alphanumeric characters, periods, underscores, hyphens, and parentheses."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources (merged with default tags)"
  type        = map(string)
  default     = {}
}

# =============================================================================
# NETWORK CONFIGURATION VARIABLES
# =============================================================================

variable "vnet_name" {
  description = "Name of the virtual network where the VM will be deployed"
  type        = string
  default     = "vnet-demo"
}

variable "subnet_name" {
  description = "Name of the subnet within the virtual network where the VM will be deployed"
  type        = string
  default     = "snet-desktops"
}

variable "vnet_resource_group_name" {
  description = "Name of the resource group containing the virtual network (if different from VM resource group)"
  type        = string
  default     = null
}

# =============================================================================
# VIRTUAL MACHINE CONFIGURATION VARIABLES
# =============================================================================

variable "vm_config" {
  description = "Virtual machine configuration object"
  type = object({
    name    = string
    vm_size = string
    vm_zone = optional(list(string), null)
  })
  default = {
    name    = "vm-demo"
    vm_size = "Standard_B2ms"
    vm_zone = null
  }
  
  validation {
    condition = contains([
      # General Purpose
      "Standard_B2ms", "Standard_B4ms", "Standard_B8ms", "Standard_B12ms", "Standard_B16ms", 
      "Standard_D1_v2", "Standard_D2_v2", "Standard_D3_v2", "Standard_D4_v2", "Standard_D5_v2",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3", "Standard_D16s_v3",
      "Standard_D2s_v4", "Standard_D4s_v4", "Standard_D8s_v4", "Standard_D16s_v4",
      "Standard_D2s_v5", "Standard_D4s_v5", "Standard_D8s_v5", "Standard_D16s_v5"
    ], var.vm_config.vm_size)
    error_message = "VM size must be an approved Azure virtual machine size."
  }
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\-]+$", var.vm_config.name))
    error_message = "VM name must contain only alphanumeric characters, underscores, and hyphens."
  }
}

variable "admin_username" {
  description = "Administrator username for the virtual machine"
  type        = string
  default     = "vmadmin"
  validation {
    condition = !contains([
      "admin", "administrator", "root", "guest", "public", "test", "test1", "test2", "test3", "user", "user1", "user2", "user3"
    ], lower(var.admin_username))
    error_message = "Admin username cannot be a reserved username."
  }
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_\\-]{0,19}$", var.admin_username))
    error_message = "Admin username must start with a letter and be 1-20 characters long, containing only letters, numbers, underscores, and hyphens."
  }
}

variable "admin_password" {
  description = "Administrator password for the virtual machine"
  type        = string
  sensitive   = true
  default     = "TempPassword123!" # WE WOULD NEVER DO THIS IN PRODUCTION - JUST FOR DEMO PURPOSES
  validation {
    condition = length(var.admin_password) >= 8 && length(var.admin_password) <= 123
    error_message = "Admin password must be between 8 and 256 characters long."
  }
  validation {
    condition = can(regex(".*[a-z].*", var.admin_password)) && can(regex(".*[A-Z].*", var.admin_password)) && can(regex(".*[0-9].*", var.admin_password))
    error_message = "Admin password must contain at least one lowercase letter, one uppercase letter, and one digit."
  }
}

# =============================================================================
# VIRTUAL MACHINE IMAGE CONFIGURATION
# =============================================================================

variable "vm_image_config" {
  description = "Virtual machine image configuration object"
  type = object({
    storage_os_disk = object({
      managed_disk_type = string
    })
    storage_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    plan = optional(object({
      name      = string
      product   = string
      publisher = string
    }), null)
  })
  default = {
    storage_os_disk = {
      managed_disk_type = "StandardSSD_LRS"
    }
    storage_image_reference = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "Windows-11"
      sku       = "win11-22h2-ent"
      version   = "latest"
    }
    plan = null
  }
  
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"
    ], var.vm_image_config.storage_os_disk.managed_disk_type)
    error_message = "Managed disk type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS."
  }
}

# =============================================================================
# DATA DISK CONFIGURATION VARIABLES
# =============================================================================

variable "data_disk_config" {
  description = "Configuration for additional data disks to attach to the VM"
  type = object({
    disk_size_gb         = number
    storage_account_type = string
    caching              = string
    lun                  = number
  })
  default = {
    disk_size_gb         = 128
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
    lun                  = 0
  }
  
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS", "UltraSSD_LRS"
    ], var.data_disk_config.storage_account_type)
    error_message = "Storage account type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS, UltraSSD_LRS."
  }
  
  validation {
    condition = contains([
      "None", "ReadOnly", "ReadWrite"
    ], var.data_disk_config.caching)
    error_message = "Caching must be one of: None, ReadOnly, ReadWrite."
  }
  
  validation {
    condition = var.data_disk_config.disk_size_gb >= 1 && var.data_disk_config.disk_size_gb <= 512
    error_message = "Disk size must be between 1 and 512 GB."
  }
  
  validation {
    condition = var.data_disk_config.lun >= 0 && var.data_disk_config.lun <= 5
    error_message = "LUN must be between 0 and 5."
  }
}