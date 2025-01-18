
# В разработке

## Общая информация
Проект предназначен для автоматизированного развертывания инфраструктуры в Yandex Cloud с использованием Terraform и программных компонентов c использованием Ansible. Работоспособность плейбуков Ansible протестирована на Ubuntu 24.04

Для работы с Yandex Cloud рекомендуется установить утилиту `yc` по [инструкции Yandex](https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-quickstart).


## Настройка Terraform

### Установка
Следуйте [инструкции по установке и настройке Terraform от Yandex](https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-quickstart).

### Настройка переменных
Все необходимые переменные находятся в шаблоне `terraform.tfvars.sample`. Перед использованием:
1. Переименуйте файл в `terraform.tfvars`.
2. Ознакомьтесь с содержимым и при необходимости измените значения переменных.

### Получение токена Yandex Cloud
Выполните следующие команды:
```bash
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```

### Развертывание инфраструктуры
Для поднятия инфраструктуры выполните:
```bash
terraform init
terraform plan
terraform apply
```
На этом этапе будут созданы виртуальные машины, количество и ресурсы которых определены в файле terraform.tfvars. Так-же будут созданы файлы ansible/inventories/hosts.yaml и 
ansible/inventories/hosts.ini содержащие имена хостов (которые соответствуют именам в списке переменной vm в файле terraform.tfvars) и ip адреса для дальнейшей работы с ansible.


## Настройка Ansible

### Общая информация
Перед началом работы с Ansible перейдите в директорию `ansible/`. 

### Переменные
- **Общие переменные**: находятся в файле `inventories/group_vars/all/vars.yaml`.
- **Секретные переменные**: пример файла находится в `creds.yaml.example`. Перед использованием:
  1. Переименуйте файл в `creds.yaml`.
  2. Укажите актуальные значения для всех переменных.
  3. Рекомендуется шифровать файл с помощью `ansible-vault`.



## Установка компонентов

## Установка коллекций-зависимостей
Для установки зависимостей выполните
```bash
ansible-galaxy collection install -r collections/reuirements.yml
```

---

## Установка всех компонентов с бэкапом на локальный хост полученных во время выполнения плейбука TLS сертификатов
Для выполнения всех ролей в рамках одного плейбука c open-source версией Angie
```bash
ansible-playbook all_playbooks.yml --tags angie
```

либо тег --angie-pro для версии Pro (Версия Pro требует наличие сертификата и ключа, подробности ниже, в разделе "Установка Angie Pro"). При первом выполнением плейбука (при условии отсутствия уже настроенного прикладного ПО) имеет смысл выполнить полное обновление системы указав в тегах дополнительно full-upgrade, например

```bash
ansible-playbook all_playbooks.yml --tags angie,full-upgrade
```

---

### Установка Angie (open-source версия)
Для установки open-source версии Angie выполните:
```bash
ansible-playbook angie.yml --tags angie
```

### Установка Angie Pro
Для установки версии Pro:
1. Добавьте ваш сертификат и ключ в директорию `./ansible/roles/web_server/files`.
2. Выполните:
   ```bash
   ansible-playbook angie.yml --tags angie-pro
   ```

### Запуск Angie в контейнере
> **Примечание**: тестировалась только установка Angie в контейнер. Конфигурация пока не пробрасывается в контейнер.

```bash
ansible-playbook angie.yml --tags angie-docker
```

---

## Установка WordPress
Для развертывания WordPress выполните:
```bash
ansible-playbook wordpress.yml
```

---

## Установка бэкендов
Для установки следующих компонентов: Keycloak, Grafana, Prometheus, PostgreSQL и тестовых бэкендов, выполните:
```bash
ansible-playbook backends.yml
```

---

## Бэкап TLS сертификатов
Для создания резервной копии TLS-сертификатов на локальном хосте выполните:
```bash
ansible-playbook backup.yml
```

---

## Примечания
- Проект находится в стадии разработки. Возможны изменения в конфигурации и функциональности.

