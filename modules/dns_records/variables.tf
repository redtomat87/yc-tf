variable "vms" {
  description = "DNS record names per VM name; only VMs with a public IP"
  type = map(object({
    dns_records = list(string)
  }))
}

variable "public_ips" {
  description = "Public IP per VM name"
  type        = map(string)
}

variable "zone_id" {
  type = string
}

variable "ttl" {
  type    = number
  default = 300
}
