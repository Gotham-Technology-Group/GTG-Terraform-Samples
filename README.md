# Windows VM Module

A comprehensive Terraform module for deploying Windows virtual machines in Microsoft Azure with best practices and sensible defaults.

## Architecture

```
┌─────────────────────┐
│   Resource Group    │
├─────────────────────┤
│ ┌─────────────────┐ │
│ │ Network Interface│ │ ──── Existing VNet/Subnet
│ └─────────────────┘ │
│ ┌─────────────────┐ │
│ │ Windows VM      │ │
│ │ • OS Disk       │ │
│ │ • Data Disk     │ │
│ └─────────────────┘ │
└─────────────────────┘
```

## Quick Start

### 1. Basic Usage

```hcl
module "windows_vm" {
  source = "./windows-vm-module"
  
  # VM Configuration
  vm_config = {
    name    = "vm-prod-web01"
    vm_size = "Standard_D4s_v5"
    vm_zone = null
  }
  
  # Network Configuration  
  vnet_name                = "vnet-production"
  subnet_name              = "snet-web-servers"
  vnet_resource_group_name = "rg-network-prod"
  
  # Authentication
  admin_username = "azureuser"
  admin_password = "ComplexPassword123!"
}
```

### 2. Access VM Information

```hcl
# Display connection information
output "vm_connection_info" {
  value = {
    vm_name            = module.windows_vm.vm_name
    private_ip_address = module.windows_vm.private_ip_address
    admin_username     = "azureuser"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.0 |

## Resources Created

| Resource | Type | Description |
|----------|------|-------------|
| `azurerm_resource_group` | Resource Group | Container for all VM resources |
| `azurerm_network_interface` | Network Interface | VM network connectivity |
| `azurerm_virtual_machine` | Virtual Machine | Windows VM instance |
| `azurerm_managed_disk` | Managed Disk | Additional data disk |
| `azurerm_virtual_machine_data_disk_attachment` | Disk Attachment | Connects data disk to VM |

## Data Sources

| Name | Description |
|------|-------------|
| `azurerm_virtual_network` | Looks up existing virtual network |
| `azurerm_subnet` | Looks up existing subnet |

## Inputs

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `vnet_name` | `string` | Name of existing virtual network |
| `subnet_name` | `string` | Name of existing subnet |
| `vnet_resource_group_name` | `string` | Resource group containing the VNet |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vm_config` | `object` | `{name="vm-demo", vm_size="Standard_B2ms", vm_zone=null}` | VM configuration |
| `location` | `string` | `"East US"` | Azure region |
| `rg_name` | `string` | `"rg-vm-demo"` | Resource group name |
| `admin_username` | `string` | `"vmadmin"` | VM administrator username |
| `admin_password` | `string` | `"TempPassword123!"` | VM administrator password |
| `data_disk_config` | `object` | See below | Data disk configuration |
| `tags` | `map(string)` | `{}` | Additional custom tags (merged with default tags) |

#### Data Disk Configuration

```hcl
data_disk_config = {
  disk_size_gb         = 128                # Size in GB (1-500)
  storage_account_type = "StandardSSD_LRS"  # Standard_LRS, StandardSSD_LRS, Premium_LRS
  caching              = "ReadWrite"        # None, ReadOnly, ReadWrite
  lun                  = 0                  # Logical Unit Number (0-5)
}
```

## Resource Tagging

The module implements a smart tagging system with global defaults and custom tag merging:

### Default Tags (Applied Automatically)
```hcl
Environment = "Development"
ManagedBy   = "Terraform"
CreatedDate = "2025-09-24"  # Auto-generated timestamp
```

### Custom Tag Merging
Pass additional tags via the `tags` variable to extend or override defaults:

```hcl
# Example: Add custom tags
module "windows_vm" {
  source = "./windows-vm-module"
  # ... other configuration ...
  
  tags = {
    Environment = "Production"    # Overrides default "Development"
    Owner       = "Platform Team" # Adds new tag
    Application = "Web Server"    # Adds new tag
  }
}

# Result: All resources get these merged tags:
# Environment = "Production"    (overridden)
# ManagedBy   = "Terraform"     (default)
# CreatedDate = "2025-09-24"    (default)
# Owner       = "Platform Team" (custom)
# Application = "Web Server"    (custom)
```

### Tag Priority
1. **Custom tags** (passed via `tags` variable) have highest priority
2. **Default tags** are applied if not overridden
3. All Azure resources created by this module receive the merged tags

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` | Virtual Machine resource ID |
| `vm_name` | Virtual Machine name |
| `vm_resource_group_name` | Resource group name |
| `nic_id` | Network interface ID |
| `private_ip_address` | **Primary private IP address** |
| `data_disk_id` | Data disk resource ID |
| `data_disk_name` | Data disk name |

## Usage Examples

### Production VM with Premium Storage

```hcl
module "production_vm" {
  source = "./windows-vm-module"
  
  vm_config = {
    name    = "vm-prod-app01"
    vm_size = "Standard_D8s_v5"
    vm_zone = ["1"]  # Availability Zone 1
  }
  
  location = "East US"
  rg_name  = "rg-production-vms"
  
  # Network Configuration
  vnet_name                = "vnet-production"
  subnet_name              = "snet-application-servers"
  vnet_resource_group_name = "rg-network-production"
  
  # Storage Configuration
  vm_image_config = {
    storage_os_disk = {
      managed_disk_type = "Premium_LRS"
    }
    storage_image_reference = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-g2"
      version   = "latest"
    }
    plan = null
  }
  
  data_disk_config = {
    disk_size_gb         = 512
    storage_account_type = "Premium_LRS"
    caching              = "ReadOnly"
    lun                  = 0
  }
  
  # Security
  admin_username = "prodadmin"
  admin_password = var.vm_admin_password  # From Key Vault or variables
  
  # Custom tags (merged with defaults: Environment="Development", ManagedBy="Terraform", CreatedDate="...")
  tags = {
    Environment = "Production"    # Overrides default
    Application = "Web Server"    # Adds new tag
    Owner       = "Platform Team" # Adds new tag
    CostCenter  = "IT-001"       # Adds new tag
  }
}
```

## Validation & Security

- **Password Complexity**: Enforces Azure password requirements (8-256 chars, mixed case, digits)
- **VM Sizes**: Validates against approved VM sizes for cost control
- **Resource Names**: Validates naming conventions and reserved names
- **Storage Types**: Validates against available Azure disk types
- **Locations**: Configurable location restrictions for compliance

## Best Practices

1. **Use Key Vault** for production passwords instead of plain text
2. **Enable Azure Backup** for production VMs (not included in this module)
3. **Configure NSGs** at the subnet and NIC level for network security (not included in this module)
4. **Use Managed Identity** instead of service principal authentication when possible
5. **Tag Resources** consistently for cost tracking and management - this module handles it automatically!
6. **Customize Tags** as needed while benefiting from sensible defaults