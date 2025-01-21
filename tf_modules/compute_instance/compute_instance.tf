resource "yandex_compute_instance" "vm" {
  for_each = { for idx, vm in var.vm : idx => vm }

  name   = each.value.name
  zone   = var.zone_of_availability
  labels = each.value.labels

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    disk_id     = yandex_compute_disk.boot-disk[each.key].id
    auto_delete = each.value.boot_disk_auto_delete
  }

  network_interface {
    subnet_id = var.subnet_ids[each.key]
    nat       = each.value.nat
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_open_key_file)}"
  }

  scheduling_policy {
    preemptible = each.value.preemptible
  }
}

resource "yandex_compute_disk" "boot-disk" {
  for_each = { for idx, vm in var.vm : idx => vm }

  name     = each.value.name
  type     = each.value.boot_disk_type
  zone     = var.zone_of_availability
  size     = each.value.boot_disk_size
  image_id = each.value.boot_disk_image
  labels   = each.value.labels
}

output "vm_instances" {
  value = [for idx, instance in yandex_compute_instance.vm : {
    name = instance.name
    network_interface = [{
      nat_ip_address = instance.network_interface.0.nat_ip_address
    }]
  }]
}

output "vm_ips" {
  value = [for idx, instance in yandex_compute_instance.vm : instance.network_interface.0.nat_ip_address]
}

output "internal_ip_addresses_with_names" {
  value = {
    for instance in yandex_compute_instance.vm :
    instance.name => instance.network_interface.0.ip_address
  }
}

output "external_ip_addresses_with_names" {
  value = {
    for instance in yandex_compute_instance.vm :
    instance.name => instance.network_interface.0.nat_ip_address
    if instance.network_interface.0.nat_ip_address != null
  }
}
