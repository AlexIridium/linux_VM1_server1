#!/bin/bash

# Скрипт для автоматической установки Prometheus, Grafana, Node Exporter и stress
# ОС: Ubuntu 22.04 | IP сервера: 10.17.86.172
# Скрипт автоматически делает себя исполняемым при запуске

# Делаем текущий скрипт исполняемым на будущее
chmod +x "$0" 2>/dev/null

# Выход при любой ошибке
set -e

echo "=== 1. Установка зависимостей для Grafana ==="
sudo apt-get install -y adduser libfontconfig1 musl

echo "=== 2. Установка Prometheus и Node Exporter ==="
sudo apt install -y prometheus prometheus-node-exporter

echo "=== 3. Настройка конфигурации Prometheus (Сбор метрик Nginx и Node Exporter) ==="
PROM_CONFIG="/etc/prometheus/prometheus.yml"

# Резервная копия оригинального конфига
sudo cp "$PROM_CONFIG" "${PROM_CONFIG}.bak"

# Перезаписываем базовый конфиг, добавляя сбор метрик с Nginx и Node Exporter
sudo bash -c "cat > $PROM_CONFIG" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'nginx'
    metrics_path: /metrics
    static_configs:
      - targets: ['10.17.86.172:80']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['10.17.86.172:9100']
EOF

# Перезапускаем Prometheus и Node Exporter для применения настроек
sudo systemctl restart prometheus
sudo systemctl enable prometheus
sudo systemctl restart prometheus-node-exporter
sudo systemctl enable prometheus-node-exporter

echo "=== 4. Установка Grafana из локального DEB-пакета ==="
GRAFANA_DEB="/home/berd/grafana/grafana_12.3.3_21957728731_linux_amd64-224190-b33d09.deb"

if [ -f "$GRAFANA_DEB" ]; then
    # Установка пакета через dpkg
    sudo dpkg -i "$GRAFANA_DEB"
    
    # Запуск и добавление Grafana в автозагрузку
    sudo systemctl daemon-reload
    sudo systemctl start grafana-server
    sudo systemctl enable grafana-server
else
    echo "Ошибка: Пакет Grafana не найден по пути $GRAFANA_DEB"
    echo "Пожалуйста, убедитесь, что файл находится в директории /home/berd/grafana/"
    exit 1
fi

echo "=== 5. Установка пакета утилит тестирования (stress) ==="
sudo apt install -y stress

echo "=== 6. Проверка статусов служб ==="
echo "Статус Prometheus:"
sudo systemctl is-active prometheus
echo "Статус Node Exporter:"
sudo systemctl is-active prometheus-node-exporter
echo "Статус Grafana:"
sudo systemctl is-active grafana-server

echo "=== Установка системы мониторинга успешно завершена! ==="
echo "Prometheus доступен по адресу: http://10.17.86.172:9090"
echo "Grafana доступна по адресу: http://10.17.86.172:3000"
