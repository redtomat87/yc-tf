locals {
  dns_records = flatten([
    for idx, vm in var.vm : [
      for dns_record in vm.dns_records : {
        key        = "${idx}-${vm.name}-${dns_record}"
        vm         = vm
        dns_record = dns_record
      }
    ]
  ])
}

resource "yandex_dns_recordset" "vm-dns" {
  for_each = { for record in local.dns_records : record.key => record }

  zone_id = var.zone_id
  name    = each.value.dns_record
  type    = "A"
  ttl     = 300
  data    = [var.vm_ips[index(var.vm, each.value.vm)]]
}
