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

variable "jump_host" {
  description = "VM with the vpn group; when set, the other VMs are reached by private IP"
  type        = string
  default     = null
}

variable "vpn_vars" {
  description = "Variables for the vpn role, written to all.vars; null without a jump host"
  type        = any
  default     = null
}

variable "inventory_file" {
  type = string
}
