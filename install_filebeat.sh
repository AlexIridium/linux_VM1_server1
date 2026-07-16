#!/bin/bash

# Скрипт для установки и настройки Filebeat на веб-сервере Nginx
# ОС: Ubuntu 22.04 | IP: 10.17.86.172 | ELK (Logstash) IP: 10.17.86.141:5400
# Скрипт автоматически делает себя исполняемым при запуске

# Делаем текущий скрипт исполняемым на будущее
chmod +x "$0" 2>/dev/null

# Выход при любой ошибке
set -e

# Переменные путей
FILEBEAT_DIR="/home/berd/filebeat"
DEB_FILE="filebeat_8.17.1_amd64-224190-a5f894.deb"

echo "=== 1. Проверка наличия пакета ==="
if [ ! -f "$FILEBEAT_DIR/$DEB_FILE" ]; then
    echo "Ошибка: Пакет $DEB_FILE не найден в директории $FILEBEAT_DIR"
    exit 1
fi

echo "=== 2. Установка Filebeat через dpkg ==="
cd "$FILEBEAT_DIR"
sudo dpkg -i "$DEB_FILE"

echo "=== 3. Конфигурация /etc/filebeat/filebeat.yml ==="
# Полностью перезаписываем конфигурацию для отправки логов Nginx на удаленный Logstash
sudo bash -c "cat > /etc/filebeat/filebeat.yml" << 'EOF'
filebeat.inputs:
- type: filestream
  paths:
    - /var/log/nginx/*.log
  enabled: true
  exclude_files: ['.gz$']
  prospector.scanner.exclude_files: ['.gz$']

# Блок output.elasticsearch закомментирован
# output.elasticsearch:
#   hosts: ["localhost:9200"]

output.logstash:
  hosts: ["10.17.86.141:5400"]
EOF

echo "=== 4. Перезапуск и добавление Filebeat в автозагрузку ==="
sudo systemctl daemon-reload
sudo systemctl enable filebeat
sudo systemctl restart filebeat

echo "=== 5. Проверка статуса службы ==="
sudo systemctl is-active filebeat

echo "=== Установка Filebeat на сервере 10.17.86.172 успешно завершена! ==="
echo "Логи Nginx перенаправляются на Logstash -> 10.17.86.141:5400"
