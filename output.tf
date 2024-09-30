output "internal_ip_addresses_with_names" {
  value = {
    for instance in yandex_compute_instance.vm :
    instance.name => instance.network_interface.0.ip_address
  }
}

output "external_ip_addresses_with_names" {
  value = {
    for instance in yandex_compute_instance.vm :
    instance.name => instance.network_interface.0.nat_ip_address
    if instance.network_interface.0.nat_ip_address != null
  }
}


output "fqdn_with_internal_ip_addresses" {
  value = {
    for instance in yandex_compute_instance.vm :
    instance.fqdn => instance.network_interface.0.ip_address
  }
}