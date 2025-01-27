resource "local_file" "ansible_inventory_ini" {
  content = <<EOF
[all:vars]
ansible_user=user

${join("\n", flatten([
  for env in distinct([for instance in var.vm_instances : instance.labels.environment]) : [
    "[${env}]",
    join("\n", [
      for instance in var.vm_instances :
      "${instance.name} ansible_host=${instance.network_interface[0].nat_ip_address}"
      if instance.labels.environment == env
    ]),
    "",
    "[${env}:children]",
    join("\n", distinct([for instance in var.vm_instances : "${env}-${instance.labels.role}" if instance.labels.environment == env]))
  ]
  ]))}

${join("\n", flatten([
  for instance in var.vm_instances :
  [
    "[${instance.labels.environment}-${instance.labels.role}]",
    "${instance.name} ansible_host=${instance.network_interface[0].nat_ip_address}"
  ]
]))}
EOF
filename = "${path.root}/ansible/inventories/hosts.ini"
}

resource "local_file" "ansible_inventory_yaml" {
  content = yamlencode({
    all = {
      groups = {
        for env in distinct([for instance in var.vm_instances : instance.labels.environment]) : env => {
          children = {
            for role in distinct([for instance in var.vm_instances : instance.labels.role if instance.labels.environment == env]) : role => {
              hosts = {
                for instance in var.vm_instances :
                instance.name => {
                  ansible_host = instance.network_interface[0].nat_ip_address
                  ansible_user = "user"
                }
                if instance.labels.role == role && instance.labels.environment == env
              }
            }
          }
        }
      }
    }
  })
  filename = "${path.root}/ansible/inventories/hosts.yaml"
}

output "ansible_inventory_ini" {
  value = local_file.ansible_inventory_ini.content
}

output "ansible_inventory_yaml" {
  value = local_file.ansible_inventory_yaml.content
}
