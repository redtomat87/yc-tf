# State в Object Storage. bucket и ключи доступа приходят из backend.s3.tfbackend,
# его создаёт стек bootstrap/:
#   terraform init -backend-config=backend.s3.tfbackend
terraform {
  backend "s3" {
    key    = "yandex_cloud_vm/terraform.tfstate"
    region = "ru-central1"

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    # Блокировка через lock-файл в бакете (conditional writes), без YDB.
    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
