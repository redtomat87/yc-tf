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

variable "dns_zone" {
  type    = string
  default = ""
}

variable "common_labels" {
  type = map(string)
}

variable "ssh_allowed_cidrs" {
  description = "CIDRs allowed to reach SSH on the VMs"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every entry must be a valid CIDR, e.g. 203.0.113.10/32."
  }
}

variable "public_tcp_ports" {
  description = "TCP ports open to the internet"
  type        = list(number)
  default     = [80, 443]
}

variable "public_udp_ports" {
  description = "UDP ports open to the internet (443 for HTTP/3)"
  type        = list(number)
  default     = [443]
}

variable "networks" {
  type = map(object({
    subnets = map(object({
      cidr_block = string
    }))
  }))
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
    labels                = map(string)
  }))
}

