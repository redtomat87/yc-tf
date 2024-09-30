resource "yandex_vpc_network" "my-network" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "subnet-a-zone" {
  name           = var.subnet_name
  zone           = var.zone_of_availability
  network_id     = yandex_vpc_network.my-network.id
  v4_cidr_blocks = var.v4_cidr_blocks
  labels         = var.labels
}