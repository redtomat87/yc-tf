# В разработке.
Для работы с Yandex Cloud реукомендуется установить утилиту yc по инструкции yandex https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-quickstart
Чтобы использовать terraform манифесты для создания инфраструктуры (написано для Yandex Cloud) следуйте инструкции по установке и настройке
terraform от Yandex cloud https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-quickstart
Необходимые переменные храняться в темплейте terraform.tfvars.sample. Перед запуском переименуйте файл в terraform.tfvars предварительно ознакомившись с переменными и их значением.

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
Для установки и настройки software компонентов используйте ansible, перед запуском перейдите в дирректорию ansible/
Переменные находятся в директории inventories/group_vars/all/
В файле vars.yaml находятся не секретные переменные. В файле creds.yaml.example находятся секретные переменные. Перед использованием
Переименуйте файл в creds.yaml, измените значения переменных с учётными данными. После чего рекомендуем этот файл заливать в репозиторий исключительно в шифрованном виде (например с помощью ansible-vault)
Для установки open-source версии Angie выполните
```
ansible-playbook angie.yml --tags angie
```
Для того чтобы установить из репозиториев Angie-pro, *для установки версии PRO требуется добавить ваш файл сертификата и ключа в директорию ./ansible/roles/web_server/files
```
ansible-playbook angie.yml --tags angie-pro
```
Чтобы запустить angie в контейнере используйте (прим. тестировалась только установка Angie в контейнер, конфигурация на данный момент в контейнер не пробрасывается)
```
ansible-playbook angie.yml --tags angie-docker
```
Для установки worpress
```
ansible-playbook wordpress.yml
```
Для установки бэкендов (Keycloak, Grafana, Prometheus, PostgreSQL и тестовых бэкендов)
```
ansible-playbook backends.yml
``` 
Для бэкапа TLS сертификатов на локальный хост
```
ansible-playbook backup.yml 
```