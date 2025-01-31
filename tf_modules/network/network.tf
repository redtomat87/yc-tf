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

output "subnet_ids" {
  value = {
    for key, subnet in yandex_vpc_subnet.vm-subnet :
    key => subnet.id
  }
}
