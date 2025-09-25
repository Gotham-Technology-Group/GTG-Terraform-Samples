terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
    # Leave these commented out for now to allow easier local testing
    # resource_group_name = var.backend_resource_group_name
    # storage_account_name = var.backend_storage_account_name
    # container_name = var.backend_container_name
    # key = var.backend_key
    # subscription_id = var.subscription_id
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# =============================================================================
# LOCAL VALUES FOR TAG MANAGEMENT
# =============================================================================

locals {
  # Default tags that apply to all resources
  default_tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Merge default tags with any additional tags passed via variables
  # Additional tags will override defaults if same key is used
  merged_tags = merge(local.default_tags, var.tags)
}

# Data source to look up the virtual network
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network
data "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

# Data source to look up the subnet
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet
data "azurerm_subnet" "this" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

# Create a new Resource Group to place the VM into
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "this" {
  name     = var.rg_name
  location = var.location
  tags     = local.merged_tags
}

# Create a Network Interface for the VM
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "this" {
  name                = "nic-${var.vm_config.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.merged_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a Managed Disk for the VM's data disk
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk
resource "azurerm_managed_disk" "data_disk" {
  name                 = "datadisk-${var.vm_config.name}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = var.data_disk_config.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_config.disk_size_gb
  tags                 = local.merged_tags
}


# Create the Virtual Machine
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine
resource "azurerm_virtual_machine" "this" {
  name                         = var.vm_config.name
  location                     = var.location
  tags                         = local.merged_tags
  resource_group_name          = azurerm_resource_group.this.name
  vm_size                      = var.vm_config.vm_size
  network_interface_ids        = [azurerm_network_interface.this.id]
  primary_network_interface_id = azurerm_network_interface.this.id
  zones                        = var.vm_config.vm_zone

  os_profile {
    computer_name  = var.vm_config.name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
  delete_os_disk_on_termination = true
  storage_os_disk {
    name              = "os-${var.vm_config.name}"
    caching           = "ReadWrite"
    managed_disk_type = var.vm_image_config.storage_os_disk.managed_disk_type
    create_option     = "FromImage"
  }
  storage_image_reference {
    publisher = var.vm_image_config.storage_image_reference.publisher
    offer     = var.vm_image_config.storage_image_reference.offer
    sku       = var.vm_image_config.storage_image_reference.sku
    version   = var.vm_image_config.storage_image_reference.version
  }
  
  # Only include plan block if plan is not null
  dynamic "plan" {
    for_each = var.vm_image_config.plan != null ? [var.vm_image_config.plan] : []
    content {
      name      = plan.value.name
      product   = plan.value.product
      publisher = plan.value.publisher
    }
  }
  
  timeouts {
    create =  "1h30m"
    delete =  "20m"
  }
  lifecycle {
    ignore_changes = [
      vm_size,
      os_profile,
      identity,
      tags,
    ]
  }
  depends_on = [ azurerm_network_interface.this ]
}

# Attach the data disk to the VM
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_virtual_machine.this.id
  lun                = var.data_disk_config.lun
  caching            = var.data_disk_config.caching
}