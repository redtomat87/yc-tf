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
Положите файл сертификата и ключа в директорию ansible/roles/web_server/files

Для установки используйте ansible, чтобы запустить контейнер используйте
```
ansible-playbook -v angie.yml --tags angie-docker
```
Для того чтобы установить из репозиториев Angie-pro
```
ansible-playbook -v angie.yml --tags angie
```