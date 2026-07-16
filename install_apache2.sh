#!/bin/bash

# Скрипт для установки Apache2 и настройки балансировки Round Robin через Nginx
# ОС: Ubuntu 22.04 | IP: 10.17.86.172 (Порты 8080 и 8081)
# Скрипт автоматически делает себя исполняемым при запуске

# Делаем текущий скрипт исполняемым на будущее
chmod +x "$0" 2>/dev/null

# Выход при любой ошибке
set -e

echo "=== 1. Установка Apache2 ==="
sudo apt install -y apache2

echo "=== 2. Настройка портов в ports.conf ==="
# Указываем Apache2 слушать порты 8080 и 8081 вместо стандартного 80
sudo bash -c "cat > /etc/apache2/ports.conf" << 'EOF'
Listen 8080
Listen 8081
EOF

echo "=== 3. Создание директорий и стартовых страниц для проверки ==="
# Директория для порта 8080
sudo mkdir -p /var/www/html/site_8080
sudo bash -c "echo '<h1>Hi! This is the port 8080 from Apache2 (Port 8080)</h1>' > /var/www/html/site_8080/index.html"

# Директория для порта 8081
sudo mkdir -p /var/www/html/site_8081
sudo bash -c "echo '<h1>Hi! This is the port 8081 from Apache2 (Port 8081)</h1>' > /var/www/html/site_8081/index.html"

echo "=== 4. Создание конфигурации Виртуальных Хостов Apache2 ==="
# Конфигурация для хоста 8080
sudo bash -c "cat > /etc/apache2/sites-available/000-default.conf" << 'EOF'
<VirtualHost 10.17.86.172:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/site_8080
    
    # Настройка логов (впоследствии будут отправляться в ELK)
    ErrorLog ${APACHE_LOG_DIR}/error_8080.log
    CustomLog ${APACHE_LOG_DIR}/access_8080.log combined
</VirtualHost>

<VirtualHost 10.17.86.172:8081>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/site_8081
    
    ErrorLog ${APACHE_LOG_DIR}/error_8081.log
    CustomLog ${APACHE_LOG_DIR}/access_8081.log combined
</VirtualHost>
EOF

echo "=== 5. Перезапуск службы Apache2 ==="
sudo systemctl restart apache2
sudo systemctl enable apache2

echo "=== 6. Обновление конфигурации Nginx под Round Robin балансировку ==="
# Перезаписываем созданный ранее файл конфигурации Nginx, добавляя upstream-блок балансировщика
NGINX_CONFIG="/etc/nginx/sites-available/wordpress_proxy.conf"

if [ -f "$NGINX_CONFIG" ]; then
sudo bash -c "cat > $NGINX_CONFIG" << 'EOF'
# Определение пула серверов для балансировки (по умолчанию используется Round Robin)
upstream apache_backend {
    server 10.17.86.172:8080;
    server 10.17.86.172:8081;
}

server {
    listen 80;
    server_name 10.17.86.172;

    # Логи в формате JSON для отправки в ELK Stack (10.17.86.141)
    access_log /var/log/nginx/wp_access_json.log json_analytics;
    error_log /var/log/nginx/wp_error.log;

    client_max_body_size 64M;

    location / {
        # Перенаправление запроса на пул балансировки
        proxy_pass http://apache_backend;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_read_timeout 90;
    }
}
EOF

    echo "Перезапуск Nginx для применения балансировки..."
    sudo nginx -t
    sudo systemctl restart nginx
else
    echo "Предупреждение: Конфигурационный файл Nginx не найден. Настройте проксирование на http://apache_backend вручную."
fi

echo "=== Настройка Apache2 и балансировки успешно завершена! ==="
