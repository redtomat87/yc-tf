locals {
  image_families = toset([for vm in var.vms : vm.image_family])
}

data "yandex_compute_image" "family" {
  for_each = local.image_families

  family = each.key
}

resource "yandex_compute_disk" "boot" {
  for_each = var.vms

  name     = "${each.key}-boot"
  type     = each.value.boot_disk_type
  zone     = var.zone_of_availability
  size     = each.value.boot_disk_size
  image_id = data.yandex_compute_image.family[each.value.image_family].id
  labels   = each.value.labels

  lifecycle {
    # Новый образ в family не должен пересоздавать диск с данными.
    ignore_changes = [image_id]
  }
}

resource "yandex_compute_instance" "vm" {
  for_each = var.vms

  name        = each.key
  hostname    = each.key
  platform_id = each.value.platform_id
  zone        = var.zone_of_availability
  labels      = each.value.labels

  allow_stopping_for_update = true

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    disk_id     = yandex_compute_disk.boot[each.key].id
    auto_delete = each.value.boot_disk_auto_delete
  }

  network_interface {
    subnet_id          = var.subnet_ids["${each.value.network_name}-${each.value.subnet_name}"]
    nat                = each.value.nat
    security_group_ids = [var.security_group_ids[each.value.network_name]]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_open_key_file)}"
  }

  scheduling_policy {
    preemptible = each.value.preemptible
  }
}

output "vms" {
  description = "Addresses and labels per VM name"
  value = {
    for name, instance in yandex_compute_instance.vm : name => {
      private_ip = instance.network_interface[0].ip_address
      public_ip  = instance.network_interface[0].nat_ip_address
      labels     = instance.labels
    }
  }
}
