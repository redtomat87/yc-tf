resource "local_file" "ansible_inventory_ini" {
  content = <<EOF
[all:vars]
ansible_user=ubuntu

[all]
${join("\n", [for instance in yandex_compute_instance.vm :
"${instance.name} ansible_host=${instance.network_interface.0.nat_ip_address}"])}
EOF
filename = "${path.module}/hosts.ini"
}

resource "local_file" "ansible_inventory_yaml" {
  content = yamlencode({
    "all" : {
      "hosts" : {
        for instance in yandex_compute_instance.vm :
        instance.name => {
          "ansible_host" : instance.network_interface.0.nat_ip_address,
          "ansible_user" : "ubuntu"
        }
      }
    }
  })
  filename = "${path.module}/hosts.yaml"
}