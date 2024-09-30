resource "yandex_compute_instance" "vm" {
  count  = length(var.vm)
  name   = var.vm[count.index]
  zone   = var.zone_of_availability
  labels = var.labels

  resources {
    cores         = var.vm_cores
    memory        = var.vm_memory
    core_fraction = var.vm_core_fraction
  }

  boot_disk {
    disk_id     = yandex_compute_disk.boot-disk[count.index].id
    auto_delete = var.vm_boot_disk_auto_delete
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-a-zone.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_open_key_file)}"
  }

  scheduling_policy {
    preemptible = true
  }
}

