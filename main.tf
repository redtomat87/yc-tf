module "network" {
  source               = "./tf_modules/network"
  zone_of_availability = var.zone_of_availability
  vm                   = var.vm
  labels               = var.labels
}

module "compute_instance" {
  source = "./tf_modules/compute_instance"

  vm                   = var.vm
  zone_of_availability = var.zone_of_availability
  labels               = var.labels
  subnet_ids           = module.network.subnet_ids
  ssh_open_key_file    = var.ssh_open_key_file
}

module "dns" {
  source = "./tf_modules/dns_recordsets"

  vm                   = var.vm
  zone_id              = yandex_dns_zone.redtomat-ru.id
  vm_ips               = module.compute_instance.vm_ips
  zone_of_availability = var.zone_of_availability
}

module "ansible_inventory" {
  source = "./tf_modules/ansible_inventory"

  vm_instances = module.compute_instance.vm_instances
}

