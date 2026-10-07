locals {
  vms = {
    for name, vm in var.vms : name => merge(vm, {
      labels = merge(var.common_labels, vm.labels)
    })
  }

  # Jump-хост — ВМ с группой vpn. Если он есть, SSH из интернета открыт только на нём,
  # а на остальные ВМ Ansible ходит по частным адресам через туннель WireGuard.
  jump_host = one([for name, vm in var.vms : name if contains(vm.ansible_groups, "vpn")])

  nat_gateway_networks = toset([for vm in var.vms : vm.network_name if !vm.nat])
  vpn_networks         = local.jump_host == null ? toset([]) : toset([var.vms[local.jump_host].network_name])

  # SSH снаружи — jump-хосту, а без него всем ВМ с публичным адресом. Веб — ВМ с группой web.
  vm_security_groups = {
    for name, vm in var.vms : name => compact([
      module.network.security_group_ids[vm.network_name].internal,
      (local.jump_host == null ? vm.nat : name == local.jump_host) ? module.network.security_group_ids[vm.network_name].ssh : null,
      contains(vm.ansible_groups, "web") ? module.network.security_group_ids[vm.network_name].public : null,
      name == local.jump_host ? module.network.security_group_ids[vm.network_name].vpn : null,
    ])
  }
}

module "network" {
  source               = "./modules/network"
  zone_of_availability = var.zone_of_availability
  networks             = var.networks
  common_labels        = var.common_labels
  ssh_allowed_cidrs    = var.ssh_allowed_cidrs
  public_tcp_ports     = var.public_tcp_ports
  public_udp_ports     = var.public_udp_ports
  nat_gateway_networks = local.nat_gateway_networks
  vpn_networks         = local.vpn_networks
  vpn_port             = var.vpn_port
}

module "compute" {
  source = "./modules/compute"

  vms                  = local.vms
  zone_of_availability = var.zone_of_availability
  subnet_ids           = module.network.subnet_ids
  security_group_ids   = local.vm_security_groups
  ssh_user             = var.ssh_user
  ssh_public_key_file  = var.ssh_public_key_file
}

module "dns" {
  source = "./modules/dns_records"

  vms        = { for name, vm in local.vms : name => vm if vm.nat }
  public_ips = { for name, vm in module.compute.vms : name => vm.public_ip if local.vms[name].nat }
  zone_id    = yandex_dns_zone.redtomat-ru.id
}

module "ansible_inventory" {
  source = "./modules/ansible_inventory"

  vms = {
    for name, vm in module.compute.vms : name => merge(vm, {
      ansible_groups = local.vms[name].ansible_groups
    })
  }
  ssh_user  = var.ssh_user
  jump_host = local.jump_host
  # Порт WireGuard и сети, которые клиент VPN маршрутизирует в туннель.
  vpn_vars = local.jump_host == null ? null : {
    vpn_port   = var.vpn_port
    vpn_routes = module.network.subnet_cidrs[var.vms[local.jump_host].network_name]
  }
  inventory_file = "${path.root}/ansible/inventories/yc/hosts.yml"
}
