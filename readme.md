# yandex_cloud_vm

Пет-проект: Terraform поднимает ВМ в Yandex Cloud (Ubuntu 26.04) и пишет для
них ansible inventory, Ansible разворачивает на ВМ:

- **Angie** из репозитория вендора: TLS через встроенный ACME (Let's Encrypt),
  HTTP/2 и HTTP/3, свой профиль AppArmor;
- **статический сайт** — static.redtomat.ru;
- **в контейнерах Podman 6** (Kubernetes YAML + Quadlet `.kube`, rootful,
  `UserNS=auto`, профиль AppArmor `containers-default`):
  - WordPress + MySQL 8.4 + mysqld_exporter — daily.redtomat.ru;
  - Keycloak ×2 (кластер, jdbc-ping) + PostgreSQL 18 — auth.redtomat.ru;
  - Grafana (вход через Keycloak) и Prometheus, отдельные pod'ы — grafana.redtomat.ru, `/prometheus`;
  - prometheus-podman-exporter, node_exporter;
  - 4 тестовых бэкенда для экспериментов с балансировкой — angie-backend.redtomat.ru;
- консоль Angie — angie.redtomat.ru/console/.

Снаружи открыты только 22, 80, 443/tcp и 443/udp (security group). Всё
остальное слушает 127.0.0.1, вход — только через Angie.

Схема: [docs/architecture.drawio](docs/architecture.drawio).

## Что где

```
bootstrap/                  бакет Object Storage для state + сервисный аккаунт (свой локальный state)
versions.tf backend.tf      версии, s3 backend с use_lockfile
variables.tf main.tf        ВМ описываются map'ой vms в terraform.tfvars (пример — terraform.tfvars.sample)
modules/network             VPC, подсети, security group
modules/compute             образ по family, диск, ВМ, статический IP, cloud-init
modules/dns_records         A-записи в зоне dns_zone
modules/ansible_inventory   ansible/inventories/yc/hosts.yml
ansible/
  site.yml                  всё по порядку: base -> podman -> web -> apps -> verify
  base.yml podman.yml web.yml apps.yml verify.yml acme-backup.yml
  group_vars/all/main.yml   домены, порты, vhost'ы, слоты UserNS
  group_vars/all/topology.yml  где какие сервисы: группы, адреса между ВМ, реплики Keycloak
  group_vars/all/vault.yml  секреты (ansible-vault, пароль в ansible/.vault); структура — vault.yml.example
  inventories/yc            генерирует Terraform
  inventories/local         локальный стенд (libvirt), LE staging
  roles/base                пакеты, AppArmor, node_exporter, fail2ban
  roles/podman              Podman 6 из OBS home:alvistack с apt pinning
  roles/podman_kube         общий механизм: манифест + Quadlet .kube, рестарт, ожидание healthy
  roles/angie               angie.conf + http.d/*, проверка angie -t и откат, ACME, AppArmor
  roles/static_site         сайт из roles/static_site/files/static_site.zip (не в git)
  roles/wordpress roles/keycloak roles/monitoring roles/test_backends
```

Ansible разложен по [standard layout](https://docs.ansible.com/projects/ansible/latest/tips_tricks/sample_setup.html)
с одним отличием: инвентари собраны в `inventories/`. `group_vars/` лежит рядом с плейбуками
и общий для обоих инвентарей: конфигурация облака и локального стенда одна, а `inventories/yc/`
целиком генерирует Terraform. Это playbook group_vars, и по
[приоритету](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence)
они сильнее переменных группы из файла inventory, но слабее переменных хоста. Поэтому
переопределения для стенда задаются на уровне хоста, как в `inventories/local/hosts.yml`.

## Подготовка

Нужно на машине администратора: `yc`, Terraform ≥ 1.10, Ansible core ≥ 2.18,
коллекции из `ansible/requirements.yml`, `passlib` для Python, на котором
работает Ansible (хэши basic auth), `openssl`.

```bash
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
ansible-galaxy collection install -r ansible/requirements.yml
```

### State в Object Storage (один раз)

```bash
cd bootstrap
terraform init
terraform apply -var bucket_name=redtomat-yc-vm-tfstate
cd ..
terraform init -backend-config=backend.s3.tfbackend
```

`bootstrap` создаёт бакет, сервисный аккаунт с `storage.editor` на бакет и
статический ключ, и пишет `backend.s3.tfbackend` (в `.gitignore`, режим 0600).
Свой state `bootstrap` держит локально. Блокировка state — lock-файл в бакете
(`use_lockfile`), проверено: второй процесс получает `412 PreconditionFailed`.

## Инфраструктура

```bash
cp terraform.tfvars.sample terraform.tfvars   # и поправить
terraform plan
terraform apply
```

Каждая ВМ — запись в `vms`; обязательны только `network_name` и `subnet_name`,
остальное с умолчаниями (описаны в sample). Основное:

- `ansible_groups` — какие сервисы работают на ВМ (раздел «Размещение сервисов»);
- `static_ip = true` — зарезервированный адрес, не меняется при перезапуске
  preemptible-ВМ. **Переключение пересоздаёт ВМ** (около минуты простоя): провайдер
  не умеет снять статический адрес с работающей ВМ, а API не удаляет занятый адрес.
  Диск, данные и ключи хоста сохраняются;
- `dns_records` — A-записи в `dns_zone`;
- `ssh_user` (по умолчанию `user`) создаёт cloud-init, это же имя попадает в inventory.

### Размещение сервисов

Каждый сервис — группа inventory, ВМ перечисляет свои в `ansible_groups`:

| группа | что | замечания |
|---|---|---|
| `web` | Angie, статика, консоль | на эту ВМ указывают `dns_records`; одна ВМ |
| `wordpress` | WordPress + MySQL + mysqld_exporter | одна ВМ |
| `keycloak_db` | PostgreSQL для Keycloak | одна ВМ |
| `keycloak` | реплики Keycloak | одна ВМ — 2 реплики, несколько — по реплике на ВМ |
| `prometheus`, `grafana` | мониторинг | по одной ВМ |
| `test_backends` | 4 тестовых бэкенда | одна ВМ |

Все на одной ВМ — как в `terraform.tfvars.sample`. Разнести — раздать группы
разным ВМ, например:

```hcl
angie  = { ..., dns_records = [...], ansible_groups = ["web", "test_backends"] }
apps-a = { ..., ansible_groups = ["wordpress", "keycloak_db", "keycloak"] }
apps-b = { ..., ansible_groups = ["keycloak", "prometheus", "grafana"] }
```

Полный пример с правилами разноса — `terraform-multivm.tfvars.sample`.

Адреса друг друга сервисы берут из inventory (`group_vars/all/topology.yml`): на
той же ВМ — 127.0.0.1, на другой — частный IP (`private_ip`, его пишет Terraform).
Порт публикуется на частном IP, только если потребитель на другой ВМ; снаружи
частные адреса закрыты security group, внутри неё ВМ видят друг друга. Vhost
сервиса, у группы которого нет хостов, не создаётся.

Реплики Keycloak публикуют порт JGroups на частном IP и объявляют его соседям
(`cache-embedded-network-external-address`): адрес контейнера в bridge-сети с
другой ВМ недоступен. К PostgreSQL реплика ходит по имени pod'а, если он на той же
ВМ, иначе по частному IP.

## Развёртывание

```bash
cd ansible
ansible-playbook site.yml                          # всё
ansible-playbook site.yml --tags config            # только конфигурация, без установки пакетов
ansible-playbook site.yml --tags angie             # один компонент
ansible-playbook site.yml --tags full_upgrade      # плюс apt full-upgrade
ansible-playbook site.yml --check --diff           # что изменится
ansible-playbook verify.yml                        # только проверки
ansible-playbook acme-backup.yml                   # снять копию сертификатов в ansible/files/
```

Теги компонентов: `base`, `podman`, `static_site`, `angie`, `wordpress`,
`keycloak` (`keycloak_db`), `monitoring` (`prometheus`, `grafana`,
`podman_exporter`), `test_backends`. Слои: `install`, `config`, `verify`, а также
`<роль>_install`/`<роль>_config`. Повторный прогон даёт `changed=0`.

`verify.yml` (последним в `site.yml`) ничего не меняет и проверяет:

- не на loopback слушают только 22/80/443 и порты, которым нужен частный IP;
  опубликованные порты контейнеров (это правила nftables, в `ss` их нет) —
  только на 127.0.0.1 или частном IP;
- Podman ≥ 6, cgroups v2, netavark, AppArmor; Angie под профилем `angie`,
  каждый контейнер — под `containers-default` (проверка в `podman_kube`);
- каждый vhost отвечает без 5xx и с HSTS; сертификат покрывает все имена и
  действует ещё 7 дней (только с боевым CA);
- все цели Prometheus в `up`.

Первый выпуск сертификатов лучше проверить на staging, чтобы не тратить лимиты
Let's Encrypt (подробнее — раздел «ACME» ниже):

```bash
ansible-playbook site.yml -e angie_acme_ca=https://acme-staging-v02.api.letsencrypt.org/directory
```

Перед `terraform destroy` снять копию сертификатов (`acme-backup.yml`): роль angie
дольёт её на новую ВМ, и сертификаты не придётся выпускать заново.

### Локальный стенд

```bash
ansible-playbook -i inventories/local site.yml
```

ACME из частной сети не проходит, заказы идут в staging, роль их не ждёт.

## Как устроено

**Angie.** Один владелец `/etc/angie`: основной конфиг, snippets, vhost'ы
`http.d/NN-<имя>.conf` из `angie_vhosts`; чужие файлы в `http.d` удаляются.
Перед применением — `angie -t`; при ошибке возвращаются прежние версии файлов,
а если и они невалидны — снимок `/root/angie-backup/pre-ansible.tar.gz`. Reload
проверяется по generation из API статуса. Неизвестный SNI отклоняется
(`ssl_reject_handshake`). Статус и `/metrics` — только 127.0.0.1; консоль,
`/prometheus` и тестовые бэкенды — под basic auth.

**ACME (Let's Encrypt).** Один `acme_client` выпускает один сертификат на все
`server_name` из server{}, где указано `acme <клиент>`
([документация Angie](https://en.angie.software/angie/docs/configuration/acme)).
Поэтому клиентов два, `site_rsa` и `site_ecdsa`, и сертификатов тоже два: SAN на
все vhost'ы. Как настроено и почему:

- **Один аккаунт на все клиенты** — `account_key=/var/lib/angie/acme/account.key`
  у каждого `acme_client` (Angie создаёт файл сам и прямо поддерживает общий ключ).
  Без этого каждый клиент регистрирует свой аккаунт, а Let's Encrypt пускает не
  больше [10 новых регистраций за 3 часа с одного IP](https://letsencrypt.org/docs/rate-limits/#new-registrations-per-ip-address).
  Когда клиентов было по паре на vhost (12 штук), лимит срабатывал на первом же
  развёртывании.
- **Один SAN, а не сертификат на vhost** — на пересоздание ВМ уходит 2 заказа
  вместо 12 (лимит — 50 сертификатов на домен в неделю). Цена: если одно имя не
  проходит валидацию (например, нет DNS-записи нового vhost'а), не выпускается
  весь сертификат. Новый vhost добавлять вместе с его записью в `dns_records`.
- **Staging — отдельные клиенты** `site_staging_*` со своим `account_staging.key`:
  Angie не перевыпускает действующий сертификат, если сменился только URL CA, и
  без отдельных имён тестовые сертификаты остались бы после перехода на prod.
- **Копия сертификатов** — `acme-backup.yml` перед `terraform destroy`; роль angie
  доливает её на новую ВМ, и сертификаты не заказываются заново.

**Podman.** В Ubuntu 26.04 есть только 5.7, поэтому Podman 6 ставится из OBS
`home:alvistack` (ссылка с podman.io). Пакеты OBS идут с epoch `100:` и перекрыли
бы одноимённые пакеты Ubuntu, поэтому apt pinning пропускает из OBS только Podman
и его зависимости. Ключ репозитория лежит в роли, отпечаток сверяется.

**Контейнеры.** Каждый стек — Kubernetes YAML (Pod, Secret, ConfigMap, PVC) и
Quadlet-юнит `.kube`; порты публикуются в юните на 127.0.0.1, так что манифесты
пригодны для Kubernetes. `UserNS=auto` с закреплённым за каждым pod'ом слотом
UID/GID (`podman_userns_slots`): без закрепления пересозданный pod мог получить
другой диапазон и потерять доступ к своим томам. Prometheus и Grafana — отдельные
pod'ы в сети хоста: Prometheus видит экспортеры на loopback, Grafana — Prometheus.
Запросы Grafana к Keycloak (token, userinfo) идут в локальный Angie по записи
`127.0.0.1 auth.<домен>` в `/etc/hosts` хоста: с hostNetwork `hostAliases` не
работают ни в Podman, ни в Kubernetes, а на hairpin через NAT облака полагаться
нельзя. podman-exporter — отдельный pod с `UserNS=host` ради сокета Podman.

**AppArmor.** Angie — под своим профилем `angie` (enforce), контейнеры — под
`containers-default`. Свой профиль на контейнер через kube YAML задать нельзя:
в Podman 6.1 `kube play` эту аннотацию не применяет (проверено по исходникам).

## Выключение

```bash
ansible-playbook acme-backup.yml
terraform destroy -target=module.compute -target=module.network -target=module.dns -target=module.ansible_inventory
```

DNS-зона защищена `deletion_protection` и остаётся; бакет state — тоже.
