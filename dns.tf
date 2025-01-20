resource "yandex_dns_zone" "redtomat-ru" {
  name                = "redtomat"
  description         = "DNS zone for ${var.dns_zone}"
  labels              = var.common_labels
  deletion_protection = true
  zone                = var.dns_zone
  public              = true
}
