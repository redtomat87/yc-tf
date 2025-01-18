variable "vm" {
  type = list(object({
    network_name   = string
    subnet_name    = string
    v4_cidr_blocks = list(string)
  }))
}

variable "zone_of_availability" {
  type = string
}

variable "labels" {
  type = map(string)
}
