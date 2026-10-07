output "vm_id" {
  description = "ID de la machine virtuelle"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "public_ip" {
  description = "Adresse IP publique de la VM"
  value       = azurerm_public_ip.vm.ip_address
}

output "private_ip" {
  description = "Adresse IP privée de la VM"
  value       = azurerm_network_interface.nic.private_ip_address
}
