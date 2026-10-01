# Бакет Object Storage для remote state основного стека.
# Свой state этот стек держит локально (bootstrap/terraform.tfstate, в .gitignore):
# хранить state бакета в нём самом нельзя.

terraform {
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

provider "yandex" {}

data "yandex_client_config" "this" {}

resource "yandex_iam_service_account" "tfstate" {
  name        = "${var.bucket_name}-sa"
  description = "Terraform state access for ${var.bucket_name}"
}

resource "yandex_iam_service_account_static_access_key" "tfstate" {
  service_account_id = yandex_iam_service_account.tfstate.id
  description        = "Terraform s3 backend"
}

resource "yandex_storage_bucket" "tfstate" {
  bucket    = var.bucket_name
  folder_id = data.yandex_client_config.this.folder_id
  max_size  = var.bucket_max_size

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  # Версии state позволяют откатиться после неудачного apply.
  versioning {
    enabled = true
  }

  tags = var.labels
}

resource "yandex_storage_bucket_iam_binding" "tfstate_editor" {
  bucket  = yandex_storage_bucket.tfstate.bucket
  role    = "storage.editor"
  members = ["serviceAccount:${yandex_iam_service_account.tfstate.id}"]
}

# Partial backend config для основного стека: terraform init -backend-config=backend.s3.tfbackend
resource "local_sensitive_file" "backend_config" {
  filename        = "${path.module}/../backend.s3.tfbackend"
  file_permission = "0600"
  content         = <<-EOT
    bucket     = "${yandex_storage_bucket.tfstate.bucket}"
    access_key = "${yandex_iam_service_account_static_access_key.tfstate.access_key}"
    secret_key = "${yandex_iam_service_account_static_access_key.tfstate.secret_key}"
  EOT
}
