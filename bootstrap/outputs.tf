output "bucket" {
  value = yandex_storage_bucket.tfstate.bucket
}

output "backend_config_file" {
  value = abspath(local_sensitive_file.backend_config.filename)
}
