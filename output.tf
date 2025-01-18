output "internal_ip_addresses_with_names" {
  value = module.compute_instance.internal_ip_addresses_with_names
}

output "external_ip_addresses_with_names" {
  value = module.compute_instance.external_ip_addresses_with_names
}

output "ansible_inventory_ini" {
  value = module.ansible_inventory.ansible_inventory_ini
}

output "ansible_inventory_yaml" {
  value = module.ansible_inventory.ansible_inventory_yaml
}