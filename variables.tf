variable "ssh_public_key_file" {
  description = "Public key installed for ssh_user by cloud-init"
  type        = string

  validation {
    condition     = fileexists(pathexpand(var.ssh_public_key_file))
    error_message = "Public key file not found."
  }
}

variable "ssh_user" {
  description = "Login user created by cloud-init; also written to the Ansible inventory"
  type        = string
  default     = "user"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.ssh_user)) && !contains(["root", "ubuntu"], var.ssh_user)
    error_message = "ssh_user must be a valid Linux user name other than root and ubuntu."
  }
}

variable "zone_of_availability" {
  type = string
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

variable "vms" {
  description = "VMs keyed by name. Everything except network_name/subnet_name is optional."
  type = map(object({
    cores          = optional(number, 2)
    memory         = optional(number, 4)
    core_fraction  = optional(number, 100)
    platform_id    = optional(string, "standard-v3")
    preemptible    = optional(bool, false)
    image_family   = optional(string, "ubuntu-2604-lts")
    boot_disk_type = optional(string, "network-ssd")
    boot_disk_size = optional(number, 20)
    nat            = optional(bool, true)
    static_ip      = optional(bool, false)
    network_name   = string
    subnet_name    = string
    dns_records    = optional(list(string), [])
    labels         = optional(map(string), {})
    ansible_groups = optional(list(string), [])
  }))

  validation {
    condition     = alltrue([for name, vm in var.vms : can(regex("^[a-z][-a-z0-9]{1,61}[a-z0-9]$", name))])
    error_message = "VM names must be 3-63 chars: lowercase letters, digits and hyphens, starting with a letter."
  }

  validation {
    condition = alltrue(flatten([
      for vm in var.vms : [for group in vm.ansible_groups : can(regex("^[a-z_][a-z0-9_]*$", group))]
    ]))
    error_message = "ansible_groups entries must be valid Ansible group names: lowercase letters, digits and underscores."
  }

  validation {
    condition     = alltrue([for vm in var.vms : vm.nat || !vm.static_ip])
    error_message = "static_ip needs nat = true."
  }

  validation {
    condition     = alltrue([for vm in var.vms : vm.nat || length(vm.dns_records) == 0])
    error_message = "dns_records need a public IP: set nat = true for that VM."
  }

  validation {
    condition     = length(flatten([for vm in var.vms : vm.dns_records])) == length(distinct(flatten([for vm in var.vms : vm.dns_records])))
    error_message = "Each DNS record name may belong to one VM only."
  }
}

