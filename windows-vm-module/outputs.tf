# =============================================================================
# VIRTUAL MACHINE OUTPUTS - USE FOR DYNAMIC REFERENCES
# =============================================================================

output "vm_id" {
  description = "The ID of the Virtual Machine"
  value       = azurerm_virtual_machine.this.id
}

output "vm_name" {
  description = "The name of the Virtual Machine"
  value       = azurerm_virtual_machine.this.name
}

output "vm_resource_group_name" {
  description = "The name of the resource group containing the Virtual Machine"
  value       = azurerm_virtual_machine.this.resource_group_name
}

output "nic_id" {
  description = "The ID of the Network Interface attached to the Virtual Machine"
  value       = azurerm_network_interface.this.id
}

output "private_ip_address" {
  description = "The private IP address of the Virtual Machine"
  value       = azurerm_network_interface.this.private_ip_address
}

output "data_disk_id" {
  description = "The ID of the data disk attached to the Virtual Machine"
  value       = azurerm_managed_disk.data_disk.id
}

output "data_disk_name" {
  description = "The name of the data disk attached to the Virtual Machine"
  value       = azurerm_managed_disk.data_disk.name
}


# =============================================================================
# CONFIGURATION SUMMARY - USE FOR DEBUGGING OR HANDOVER
# =============================================================================

output "vm_configuration_summary" {
  description = "A summary of the Virtual Machine configuration"
  value = {
    vm_name              = azurerm_virtual_machine.this.name
    vm_size              = azurerm_virtual_machine.this.vm_size
    location             = azurerm_virtual_machine.this.location
    private_ip_address   = azurerm_network_interface.this.private_ip_address
    os_disk_type         = azurerm_virtual_machine.this.storage_os_disk[0].managed_disk_type
    data_disk_size_gb    = azurerm_managed_disk.data_disk.disk_size_gb
    data_disk_type       = azurerm_managed_disk.data_disk.storage_account_type
    admin_username       = var.admin_username
    computer_name        = var.vm_config.name
    resource_group_name  = azurerm_resource_group.this.name
  }
}