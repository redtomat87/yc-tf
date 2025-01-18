variable "ssh_open_key_file" {
  type      = string
  sensitive = true
}

variable "zone_of_availability" {
  type = string
}

variable "v4_cidr_blocks" {
  type    = list(string)
  default = ["192.168.10.0/24"]
}

variable "network_name" {
  type    = string
  default = "default"
}

variable "dns_zone" {
  type    = string
  default = ""
}

variable "subnet_name" {
  type    = string
  default = "my-subnet"
}

variable "labels" {
  type      = map(string)
  sensitive = true
}

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
    dns_records           = list(string)
    network_name          = string
    subnet_name           = string
    v4_cidr_blocks        = list(string)
  }))
}
