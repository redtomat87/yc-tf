locals {
  unique_networks = distinct([
    for vm in var.vm : "${vm.network_name}-${vm.subnet_name}"
  ])

  grouped_vms = {
    for key in local.unique_networks : key => [
      for vm in var.vm : vm if "${vm.network_name}-${vm.subnet_name}" == key
    ]
  }
}

resource "yandex_vpc_network" "vm-network" {
  for_each = { for idx, key in local.unique_networks : idx => key }

  name   = split("-", each.value)[0]
  labels = lookup(local.grouped_vms[each.value][0], "labels", {})
}

resource "yandex_vpc_subnet" "vm-subnet" {
  for_each = { for idx, key in local.unique_networks : idx => key }

  name           = split("-", each.value)[1]
  zone           = var.zone_of_availability
  network_id     = yandex_vpc_network.vm-network[each.key].id
  v4_cidr_blocks = lookup(local.grouped_vms[each.value][0], "v4_cidr_blocks", [])
  labels         = lookup(local.grouped_vms[each.value][0], "labels", {})
}

output "subnet_ids" {
  value = {
    for idx, key in local.unique_networks :
    key => yandex_vpc_subnet.vm-subnet[idx].id
  }
}