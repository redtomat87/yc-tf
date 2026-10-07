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
  route_table_id = contains(var.nat_gateway_networks, each.value.network_name) ? yandex_vpc_route_table.egress[each.value.network_name].id : null
}

# ВМ без публичного адреса выходят в интернет (образы, apt) через NAT-шлюз.
# ВМ с публичным адресом в тех же подсетях ходят через свой адрес.
resource "yandex_vpc_gateway" "egress" {
  count = length(var.nat_gateway_networks) > 0 ? 1 : 0

  name   = "vm-egress"
  labels = var.common_labels
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "egress" {
  for_each = var.nat_gateway_networks

  name       = "${each.key}-egress"
  network_id = yandex_vpc_network.vm-network[each.key].id
  labels     = var.common_labels

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.egress[0].id
  }
}

# Группы назначаются ВМ по роли (main.tf): эта — всем, остальные — только нужным.
# Контейнеры и экспортеры слушают 127.0.0.1 или частный IP, снаружи они закрыты.
resource "yandex_vpc_security_group" "vm" {
  for_each = var.networks

  name        = "${each.key}-vm"
  description = "Traffic between VMs of ${each.key} and outbound"
  network_id  = yandex_vpc_network.vm-network[each.key].id
  labels      = var.common_labels

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

resource "yandex_vpc_security_group" "ssh" {
  for_each = var.networks

  name        = "${each.key}-ssh"
  description = "SSH from ssh_allowed_cidrs"
  network_id  = yandex_vpc_network.vm-network[each.key].id
  labels      = var.common_labels

  ingress {
    description    = "ssh"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.ssh_allowed_cidrs
  }
}

resource "yandex_vpc_security_group" "public" {
  for_each = var.networks

  name        = "${each.key}-public"
  description = "Public web ports"
  network_id  = yandex_vpc_network.vm-network[each.key].id
  labels      = var.common_labels

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
}

# WireGuard не отвечает на пакеты без верного ключа, поэтому порт открыт всем.
resource "yandex_vpc_security_group" "vpn" {
  for_each = var.vpn_networks

  name        = "${each.key}-vpn"
  description = "WireGuard on the jump host"
  network_id  = yandex_vpc_network.vm-network[each.key].id
  labels      = var.common_labels

  ingress {
    description    = "wireguard"
    protocol       = "UDP"
    port           = var.vpn_port
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
  description = "Security group ids per network name: internal, ssh, public, vpn (null without a jump host)"
  value = {
    for name, sg in yandex_vpc_security_group.vm : name => {
      internal = sg.id
      ssh      = yandex_vpc_security_group.ssh[name].id
      public   = yandex_vpc_security_group.public[name].id
      vpn      = try(yandex_vpc_security_group.vpn[name].id, null)
    }
  }
}

output "subnet_cidrs" {
  description = "Subnet CIDR blocks per network name"
  value = {
    for network_name, network in var.networks : network_name => [for subnet in network.subnets : subnet.cidr_block]
  }
}
