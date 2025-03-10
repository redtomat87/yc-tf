terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.135.0"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = var.zone_of_availability
}
