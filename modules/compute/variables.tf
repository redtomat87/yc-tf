variable "vms" {
  description = "VM specs keyed by VM name, defaults already applied by the root module"
  type = map(object({
    cores                 = number
    memory                = number
    core_fraction         = number
    platform_id           = string
    preemptible           = bool
    image_family          = string
    boot_disk_type        = string
    boot_disk_size        = number
    boot_disk_auto_delete = bool
    nat                   = bool
    static_ip             = bool
    network_name          = string
    subnet_name           = string
    labels                = map(string)
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

variable "security_group_ids" {
  description = "Security group id per network name"
  type        = map(string)
}
