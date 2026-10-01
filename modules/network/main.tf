resource "yandex_vpc_network" "vm-network" {
  for_each = var.networks

  name   = each.key
  labels = var.common_labels
}

locals {
  subnets = flatten([
    for network_name, network in var.networks : [
      for subnet_name, subnet in network.subnets : {
        network_name = network_name
        subnet_name  = subnet_name
        cidr_block   = subnet.cidr_block
      }
    ]
  ])

  subnet_map = {
    for subnet in local.subnets : "${subnet.network_name}-${subnet.subnet_name}" => subnet
  }
}

resource "yandex_vpc_subnet" "vm-subnet" {
  for_each = local.subnet_map

  name           = each.value.subnet_name
  zone           = var.zone_of_availability
  network_id     = yandex_vpc_network.vm-network[each.value.network_name].id
  v4_cidr_blocks = [each.value.cidr_block]
  labels         = var.common_labels
}

# Снаружи открыты только SSH и веб. Всё остальное (контейнеры, экспортеры)
# слушает 127.0.0.1 и наружу не попадает, даже если ошибиться в конфиге ВМ.
resource "yandex_vpc_security_group" "vm" {
  for_each = var.networks

  name        = "${each.key}-vm"
  description = "Public ingress for VMs in ${each.key}"
  network_id  = yandex_vpc_network.vm-network[each.key].id
  labels      = var.common_labels

  ingress {
    description    = "ssh"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.ssh_allowed_cidrs
  }

  dynamic "ingress" {
    for_each = var.public_tcp_ports
    content {
      description    = "public tcp ${ingress.value}"
      protocol       = "TCP"
      port           = ingress.value
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.public_udp_ports
    content {
      description    = "public udp ${ingress.value}"
      protocol       = "UDP"
      port           = ingress.value
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description       = "traffic between VMs of this group"
    protocol          = "ANY"
    predefined_target = "self_security_group"
  }

  egress {
    description    = "any outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

output "subnet_ids" {
  value = {
    for key, subnet in yandex_vpc_subnet.vm-subnet :
    key => subnet.id
  }
}

output "security_group_ids" {
  description = "Security group id per network name"
  value       = { for name, sg in yandex_vpc_security_group.vm : name => sg.id }
}
