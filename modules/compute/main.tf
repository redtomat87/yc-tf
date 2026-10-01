locals {
  image_families = toset([for vm in var.vms : vm.image_family])
}

data "yandex_compute_image" "family" {
  for_each = local.image_families

  family = each.key
}

# Зарезервированный адрес не меняется при остановке preemptible-ВМ, и DNS-записи остаются верными.
resource "yandex_vpc_address" "static" {
  for_each = { for name, vm in var.vms : name => vm if vm.static_ip }

  name   = "${each.key}-public"
  labels = each.value.labels

  external_ipv4_address {
    zone_id = var.zone_of_availability
  }
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

# Провайдер не умеет снять статический адрес с работающей ВМ: пустой nat_ip_address
# он изменением не считает, а удаление занятого адреса API отклоняет (Address in use).
# Поэтому смена static_ip пересоздаёт ВМ; диск при этом сохраняется (auto_delete = false).
resource "terraform_data" "static_ip" {
  for_each = var.vms

  input = each.value.static_ip
}

resource "yandex_compute_instance" "vm" {
  for_each = var.vms

  lifecycle {
    replace_triggered_by = [terraform_data.static_ip[each.key]]
  }

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

  # Диском управляет yandex_compute_disk.boot. auto_delete = false, чтобы при пересоздании ВМ
  # диск с данными переподключался к новой ВМ, а не удалялся вместе со старой.
  boot_disk {
    disk_id     = yandex_compute_disk.boot[each.key].id
    auto_delete = false
  }

  network_interface {
    subnet_id          = var.subnet_ids["${each.value.network_name}-${each.value.subnet_name}"]
    nat                = each.value.nat
    nat_ip_address     = each.value.static_ip ? yandex_vpc_address.static[each.key].external_ipv4_address[0].address : null
    security_group_ids = [var.security_group_ids[each.value.network_name]]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      ssh_user       = var.ssh_user
      ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_file)))
    })
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
