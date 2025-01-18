variable "vm_instances" {
  type = list(object({
    name = string
    network_interface = list(object({
      nat_ip_address = string
    }))
  }))
}
