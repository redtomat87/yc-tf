resource "yandex_compute_disk" "boot-disk" {
  count    = length(var.vm)
  name     = var.vm[count.index]
  type     = var.vm_boot_disk_type
  zone     = var.zone_of_availability
  size     = var.vm_boot_disk_size
  image_id = var.vm_boot_disk_image
  labels   = var.labels
}
