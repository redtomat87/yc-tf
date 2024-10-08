resource "local_file" "ansible_ini_inventory" {
  content = join("\n", [for instance in yandex_compute_instance.vm :
  "${instance.name} ansible_host=${instance.network_interface.0.nat_ip_address} ansible_user=ubuntu"])
  filename = "${path.module}/hosts.ini"
}