resource "yandex_dns_zone" "redtomat-ru" {
  name                = "redtomat"
  description         = "DNS zone for ${var.dns_zone}"
  labels              = var.labels
  deletion_protection = true
  zone                = var.dns_zone
  public              = true
}

resource "yandex_dns_recordset" "vm-dns" {
  count   = length(var.vm)
  zone_id = yandex_dns_zone.redtomat-ru.id
  name    = "${var.vm[count.index]}.${var.dns_zone}"
  type    = "A"
  ttl     = 300
  data    = [yandex_compute_instance.vm[count.index].network_interface.0.nat_ip_address]
}