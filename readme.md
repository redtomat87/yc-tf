
# В разработке

## Общая информация
Для работы с Yandex Cloud рекомендуется установить утилиту `yc` по [инструкции Yandex](https://yandex.cloud/ru/docs/tutorials/infrastructure-management/terraform-quickstart).

Проект предназначен для автоматизированного развертывания инфраструктуры в Yandex Cloud и программных компонентов с использованием Terraform и Ansible.

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
```
