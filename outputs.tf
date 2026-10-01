output "internal_ip_addresses_with_names" {
  value = { for name, vm in module.compute.vms : name => vm.private_ip }
}

output "external_ip_addresses_with_names" {
  value = { for name, vm in module.compute.vms : name => vm.public_ip if vm.public_ip != null }
}

output "ansible_inventory_file" {
  value = module.ansible_inventory.inventory_file
}
