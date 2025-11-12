# MySQL to ClickHouse Replicator

Репликатор для синхронизации данных из MySQL в ClickHouse.

## Архитектура

```
MySQL → Replicator → ClickHouse → Grafana
```

## Структура проекта

- `Dockerfile` - образ репликатора
- `docker-compose.yml` - конфигурация для локальной разработки
- `config.yaml` - конфигурация репликатора
- `k8s/` - Kubernetes манифесты
- `helm/` - Helm chart

## Быстрый старт (Docker Compose)

```bash
docker-compose up -d
```

## Развертывание в Kubernetes

### Вариант 1: Использование Helm Chart (рекомендуется)

1. **Соберите Docker образ:**

```bash
docker build -t mysql-ch-replicator:latest .
# Или загрузите в registry:
# docker tag mysql-ch-replicator:latest your-registry/mysql-ch-replicator:latest
# docker push your-registry/mysql-ch-replicator:latest
```

2. **Настройте values.yaml:**

Отредактируйте `helm/replicator/values.yaml`:
- Укажите правильный host для ClickHouse Service
- Настройте параметры MySQL
- Проверьте StorageClass для PVC

3. **Создайте namespace (если еще не создан):**

```bash
kubectl create namespace elementary-analytics
```

4. **Установите Helm chart:**

```bash
helm install replicator ./helm/replicator -n elementary-analytics
```

5. **Проверьте статус:**

```bash
kubectl get pods -n elementary-analytics -l app.kubernetes.io/name=replicator
kubectl logs -n elementary-analytics -l app.kubernetes.io/name=replicator
```

### Вариант 2: Использование Kubernetes манифестов

1. **Соберите Docker образ** (см. выше)

2. **Создайте namespace (если еще не создан):**

```bash
kubectl create namespace elementary-analytics
```

3. **Обновите configmap.yaml:**

Измените host для ClickHouse на имя вашего Service:
```yaml
clickhouse:
  host: 'clickhouse'  # Имя Service ClickHouse
```

4. **Примените манифесты:**

```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/deployment.yaml
```

## Настройка подключения к ClickHouse

В Kubernetes репликатор подключается к ClickHouse через Service. Убедитесь, что:

1. **ClickHouse Service существует в том же namespace:**

```bash
kubectl get svc -n elementary-analytics | grep clickhouse
```

2. **Имя Service указано в config.yaml:**

В `config.yaml` или `values.yaml` укажите имя Service:
```yaml
clickhouse:
  host: 'clickhouse'  # Имя Service, не IP!
```

Если ClickHouse в другом namespace, используйте полное имя: `clickhouse.other-namespace.svc.cluster.local`

3. **Проверьте доступность:**

```bash
# Изнутри pod репликатора
kubectl exec -it -n elementary-analytics <replicator-pod> -- wget -O- http://clickhouse:8123/ping
```

## Конфигурация

### Основные параметры

- `mysql.host` - адрес MySQL сервера
- `clickhouse.host` - имя Service ClickHouse в Kubernetes
- `databases` - список баз данных и таблиц для репликации

### Фильтрация по дате

Для таблиц можно настроить фильтрацию по дате:
```yaml
table_name:
  date_filter:
    date_column: "created_at"
    start_date: "2024-01-01"
```

## Мониторинг

### Логи

```bash
kubectl logs -f -n elementary-analytics deployment/mysql-ch-replicator
```

### Healthcheck

Репликатор использует `pgrep` для проверки работоспособности процесса.

## Troubleshooting

### Репликатор не подключается к ClickHouse

1. Проверьте имя Service:
```bash
kubectl get svc -n elementary-analytics | grep clickhouse
```

2. Проверьте DNS:
```bash
kubectl exec -it -n elementary-analytics <replicator-pod> -- nslookup clickhouse
```

3. Проверьте сетевую доступность:
```bash
kubectl exec -it -n elementary-analytics <replicator-pod> -- wget -O- http://clickhouse:8123/ping
```

### Проблемы с PVC

1. Проверьте StorageClass:
```bash
kubectl get storageclass
```

2. Обновите `pvc.yaml` или `values.yaml` с правильным StorageClass

3. Проверьте статус PVC:
```bash
kubectl get pvc -n elementary-analytics replicator-data
```

### Проблемы с MySQL

Убедитесь, что MySQL доступен из кластера Kubernetes. Возможно, потребуется:
- Настроить NetworkPolicy
- Использовать ExternalName Service для внешнего MySQL

## Обновление

### Helm

```bash
helm upgrade replicator ./helm/replicator -n elementary-analytics
```

### Kubernetes манифесты

```bash
kubectl apply -f k8s/
```

## Удаление

### Helm

```bash
helm uninstall replicator -n elementary-analytics
```

### Kubernetes манифесты

```bash
kubectl delete -f k8s/
```

**Внимание:** PVC не удаляется автоматически. Для удаления данных:
```bash
kubectl delete pvc -n elementary-analytics replicator-data
```
