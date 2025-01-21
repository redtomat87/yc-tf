variable "vm" {
  type = list(object({
    name        = string
    dns_records = list(string)
  }))
}

variable "zone_id" {
  type = string
}

variable "vm_ips" {
  type = list(string)
}

variable "zone_of_availability" {
  type = string
}
