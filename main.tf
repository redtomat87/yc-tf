locals {
  vm_with_labels = [
    for vm in var.vm : merge(vm, {
      labels = merge(var.common_labels, vm.labels)
    })
  ]
}

module "network" {
  source               = "./tf_modules/network"
  zone_of_availability = var.zone_of_availability
  vm                   = local.vm_with_labels

}

module "compute_instance" {
  source = "./tf_modules/compute_instance"

  vm                   = local.vm_with_labels
  zone_of_availability = var.zone_of_availability
  subnet_ids           = module.network.subnet_ids
  ssh_open_key_file    = var.ssh_open_key_file
}

module "dns" {
  source = "./tf_modules/dns_recordsets"

  vm                   = local.vm_with_labels
  zone_id              = yandex_dns_zone.redtomat-ru.id
  vm_ips               = module.compute_instance.vm_ips
  zone_of_availability = var.zone_of_availability
}

module "ansible_inventory" {
  source = "./tf_modules/ansible_inventory"

  vm_instances = module.compute_instance.vm_instances
}


