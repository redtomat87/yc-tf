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
