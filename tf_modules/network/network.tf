resource "yandex_vpc_network" "vm-network" {
  for_each = { for idx, vm in var.vm : idx => vm }

  name   = each.value.network_name
  labels = var.labels
}

resource "yandex_vpc_subnet" "vm-subnet" {
  for_each = { for idx, vm in var.vm : idx => vm }

  name           = each.value.subnet_name
  zone           = var.zone_of_availability
  network_id     = yandex_vpc_network.vm-network[each.key].id
  v4_cidr_blocks = each.value.v4_cidr_blocks
  labels         = var.labels
}

output "subnet_ids" {
  value = { for idx, vm in var.vm : idx => yandex_vpc_subnet.vm-subnet[idx].id }
}
