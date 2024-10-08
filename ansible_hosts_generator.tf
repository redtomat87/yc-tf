resource "local_file" "ansible_ini_inventory" {
  content = <<EOF
[all:vars]
ansible_user=ubuntu

[all]
${join("\n", [for instance in yandex_compute_instance.vm :
"${instance.name} ansible_host=${instance.network_interface.0.nat_ip_address}"])}
EOF
filename = "${path.module}/hosts.ini"
}
