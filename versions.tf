terraform {
  # use_lockfile в s3 backend появился в 1.10
  required_version = ">= 1.10"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.233"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}
