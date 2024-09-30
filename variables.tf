variable "ssh_open_key_file" {
  type      = string
  sensitive = true
}

variable "v4_cidr_blocks" {
  type    = list(any)
  default = ["192.168.10.0/24"]
}


variable "network_name" {
  type    = string
  default = "default"
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
  type    = list(any)
  default = ["angie"]
}

variable "vm_boot_disk_type" {
  type    = string
  default = "network-hdd"
}

variable "vm_boot_disk_size" {
  type    = number
  default = 15
}

variable "vm_cores" {
  type    = number
  default = 1
}

variable "vm_memory" {
  type    = number
  default = 2
}

variable "vm_preemptible" {
  type = bool
}

variable "vm_nat" {
  type = bool
}

variable "zone_of_availability" {
  type    = string
  default = "ru-central1-a"
}

variable "vm_boot_disk_image" {
  type    = string
  default = "fd8tvc3529h2cpjvpkr5"
}

variable "vm_core_fraction" {
  type    = number
  default = 20
}

variable "vm_boot_disk_auto_delete" {
  type = bool
}