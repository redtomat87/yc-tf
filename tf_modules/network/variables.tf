variable "vm" {
  type = list(object({
    network_name   = string
    subnet_name    = string
    v4_cidr_blocks = list(string)
    labels         = map(string)
  }))
}

variable "zone_of_availability" {
  type = string
}
