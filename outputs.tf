# =============================================================================
# VIRTUAL MACHINE OUTPUTS
# =============================================================================

output "vm_id" {
  description = "The ID of the Virtual Machine"
  value       = module.production_vm.vm_id
}

output "vm_name" {
  description = "The name of the Virtual Machine"
  value       = module.production_vm.vm_name
}

output "vm_resource_group_name" {
  description = "The name of the resource group containing the Virtual Machine"
  value       = module.production_vm.vm_resource_group_name
}

# =============================================================================
# NETWORK OUTPUTS
# =============================================================================

output "nic_id" {
  description = "The ID of the Network Interface attached to the Virtual Machine"
  value       = module.production_vm.nic_id
}

output "private_ip_address" {
  description = "The private IP address of the Virtual Machine"
  value       = module.production_vm.private_ip_address
}

# =============================================================================
# STORAGE OUTPUTS
# =============================================================================

output "data_disk_id" {
  description = "The ID of the data disk attached to the Virtual Machine"
  value       = module.production_vm.data_disk_id
}

output "data_disk_name" {
  description = "The name of the data disk attached to the Virtual Machine"
  value       = module.production_vm.data_disk_name
}

# =============================================================================
# CONFIGURATION SUMMARY
# =============================================================================

output "vm_configuration_summary" {
  description = "A summary of the Virtual Machine configuration"
  value       = module.production_vm.vm_configuration_summary
}