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
