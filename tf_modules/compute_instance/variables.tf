variable "vm" {
  type = list(object({
    name                  = string
    cores                 = number
    memory                = number
    core_fraction         = number
    boot_disk_type        = string
    boot_disk_size        = number
    boot_disk_image       = string
    preemptible           = bool
    nat                   = bool
    boot_disk_auto_delete = bool
    labels                = map(string)
    network_name          = string
    subnet_name           = string
  }))
}

variable "zone_of_availability" {
  type = string
}

variable "ssh_open_key_file" {
  type = string
}

variable "subnet_ids" {
  type = map(string)
}