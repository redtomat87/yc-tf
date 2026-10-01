locals {
  records = merge([
    for name, vm in var.vms : {
      for record in vm.dns_records : "${name}/${record}" => {
        name = record
        vm   = name
      }
    }
  ]...)
}

resource "yandex_dns_recordset" "vm" {
  for_each = local.records

  zone_id = var.zone_id
  name    = each.value.name
  type    = "A"
  ttl     = var.ttl
  data    = [var.public_ips[each.value.vm]]
}
