output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_windows_virtual_machine.dyanmo_server_vm.public_ip_address
}

output "admin_password_server" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.dyanmo_server_vm.admin_password
}

output "admin_password_worker" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.dyanmo_worker_vm.admin_password
}