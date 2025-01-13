# В разработке.
Установите утилиту yc и работайте под сервисным аккаунтом для terraform. Используйте зеркала yandex для terraform.
Получение токена YC
```
export YC_TOKEN=$(yc iam create-token) 
export YC_CLOUD_ID=$(yc config get cloud-id)  
export YC_FOLDER_ID=$(yc config get folder-id)
```
##поднимаем инфру с помощью terraform
```
terraform init
terraform plan
terraform apply
```
Положите файл сертификата и ключа для Angie-pro в директорию ansible/roles/web_server/files

Для установки используйте ansible, чтобы запустить контейнер используйте
```
ansible-playbook angie.yml --tags angie-docker
```
Для того чтобы установить из репозиториев Angie-pro, *для установки версии PRO требуется добавить вш файл сертификата и ключа в директорию ./ansible/roles/web_server/files
```
ansible-playbook angie.yml --tags angie-pro
```
Для установки worpress
```
ansible-playbook wordpress.yml
```
Для установки TLS сертификатов для домена и включения http2/3
```
ansible-playbook tls.yml 
```
Если требуется сделать просто Backup сертификатов
```
ansible-playbook tls.yml --tags backup
``` 
Для установки тестовых бэкендов
```
ansible-playbook backends.yml
``` 