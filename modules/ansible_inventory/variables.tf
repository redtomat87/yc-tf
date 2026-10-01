variable "vms" {
  description = "Per VM name: addresses, labels and Ansible groups"
  type = map(object({
    private_ip     = string
    public_ip      = string
    labels         = map(string)
    ansible_groups = list(string)
  }))
}

variable "ssh_user" {
  type = string
}

variable "inventory_file" {
  type = string
}
