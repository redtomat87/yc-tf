locals {
  vms = {
    for name, vm in var.vms : name => merge(vm, {
      labels = merge(var.common_labels, vm.labels)
    })
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
}

module "compute" {
  source = "./modules/compute"

  vms                  = local.vms
  zone_of_availability = var.zone_of_availability
  subnet_ids           = module.network.subnet_ids
  security_group_ids   = module.network.security_group_ids
  ssh_open_key_file    = var.ssh_open_key_file
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
  ssh_user       = "ubuntu"
  inventory_file = "${path.root}/ansible/inventories/yc/hosts.yml"
}
