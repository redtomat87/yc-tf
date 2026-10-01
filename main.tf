locals {
  vm_with_labels = [
    for vm in var.vm : merge(vm, {
      labels = merge(var.common_labels, vm.labels)
    })
  ]
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

module "compute_instance" {
  source = "./tf_modules/compute_instance"

  vm                   = local.vm_with_labels
  zone_of_availability = var.zone_of_availability
  subnet_ids           = module.network.subnet_ids
  security_group_ids   = module.network.security_group_ids
  ssh_open_key_file    = var.ssh_open_key_file
}

module "dns" {
  source = "./tf_modules/dns_recordsets"

  vm      = local.vm_with_labels
  zone_id = yandex_dns_zone.redtomat-ru.id
  vm_ips  = module.compute_instance.vm_ips
}

module "ansible_inventory" {
  source       = "./tf_modules/ansible_inventory"
  vm_instances = module.compute_instance.vm_instances
}

