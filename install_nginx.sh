#!/bin/bash

# Скрипт для автоматической установки и настройки Nginx в режиме Reverse Proxy
# ОС: Ubuntu 22.04 | IP Nginx: 10.17.86.172 | ELK IP: 10.17.86.141
# Скрипт автоматически делает себя исполняемым при запуске

# Делаем текущий скрипт исполняемым на будущее
chmod +x "$0" 2>/dev/null

# Выход при любой ошибке
set -e

echo "=== 1. Установка Nginx ==="
sudo apt install -y nginx

echo "=== 2. Настройка JSON-формата логов для ELK Stack ==="
# Создаем конфигурацию логов, удобную для парсинга в Logstash/Elasticsearch
sudo bash -c "cat > /etc/nginx/conf.d/elk_log_format.conf" << 'EOF'
log_format json_analytics escape=json '{'
  '"time_local":"$time_local",'
  '"remote_addr":"$remote_addr",'
  '"remote_user":"$remote_user",'
  '"request":"$request",'
  '"status": "$status",'
  '"body_bytes_sent":"$body_bytes_sent",'
  '"request_time":"$request_time",'
  '"http_referrer":"$http_referer",'
  '"http_user_agent":"$http_user_agent",'
  '"upstream_response_time":"$upstream_response_time",'
  '"upstream_connect_time":"$upstream_connect_time",'
  '"upstream_header_time":"$upstream_header_time"'
'}';
EOF

echo "=== 3. Создание конфигурации реверс-прокси для Apache2 и WordPress ==="
# Настройка проксирования на порты Apache (8080 и 8081)
sudo bash -c "cat > /etc/nginx/sites-available/wordpress_proxy.conf" << 'EOF'
# Первый сайт Apache (Порт 8080) / Будущий WordPress
server {
    listen 80;
    server_name 10.17.86.172; # Можно заменить на доменное имя в будущем

    # Логи в формате JSON для отправки в ELK
    access_log /var/log/nginx/wp_access_json.log json_analytics;
    error_log /var/log/nginx/wp_error.log;

    # Настройки для WordPress (максимальный размер загрузки файлов)
    client_max_body_size 64M;

    location / {
        proxy_pass http://10.17.86.172:8080;
        
        # Передача реальных IP-адресов клиентов в Apache/WordPress
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Корректная обработка редиректов WordPress
        proxy_read_timeout 90;
        proxy_redirect http://10.17.86.172:8080 /;
    }
}

# Второй сайт Apache (Порт 8081)
server {
    listen 81; # Или другой порт/домен, если необходимо разделить со вторым сайтом Apache
    server_name 10.17.86.172;

    access_log /var/log/nginx/site2_access_json.log json_analytics;
    error_log /var/log/nginx/site2_error.log;

    location / {
        proxy_pass http://10.17.86.172:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "=== 4. Настройка метрик для Prometheus и Grafana ==="
# Включаем страницу stub_status для nginx-prometheus-exporter
sudo bash -c "cat > /etc/nginx/sites-available/metrics.conf" << 'EOF'
server {
    listen 80;
    server_name localhost;

    # Разрешаем доступ к метрикам только локально (для экспортера)
    location /metrics {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 10.17.86.172;
        deny all;
    }
}
EOF

echo "=== 5. Активация конфигураций и отключение дефолтного сайта ==="
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/wordpress_proxy.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/metrics.conf /etc/nginx/sites-enabled/

echo "=== 6. Проверка конфигурации Nginx и перезапуск ==="
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "=== Установка и базовая настройка Nginx реверс-прокси завершена успешно! ==="
echo "Интеграция с ELK: Логи пишутся в JSON-формате в /var/log/nginx/*_json.log"
echo "Интеграция с Prometheus: Метрики доступны по адресу http://10.17.86"
