resource "yandex_vpc_network" "my-network" {
  name = "default"
}

resource "yandex_vpc_subnet" "subnet-a-zone" {
  name           = "my-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}