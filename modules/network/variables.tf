variable "networks" {
  type = map(object({
    subnets = map(object({
      cidr_block = string
    }))
  }))
}

variable "zone_of_availability" {
  type = string
}

variable "common_labels" {
  type = map(string)
}

variable "ssh_allowed_cidrs" {
  type = list(string)
}

variable "public_tcp_ports" {
  type = list(number)
}

variable "public_udp_ports" {
  type = list(number)
}

variable "nat_gateway_networks" {
  description = "Networks with VMs that have no public IP"
  type        = set(string)
}

variable "vpn_networks" {
  description = "Networks with a jump host"
  type        = set(string)
}

variable "vpn_port" {
  type = number
}
