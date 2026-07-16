#!/bin/bash

# Скрипт для автоматической установки WordPress за балансировщиком Apache2/Nginx
# ОС: Ubuntu 22.04 | IP: 10.17.86.172 | DB: Local MySQL (Master)
# Скрипт автоматически делает себя исполняемым при запуске

# Делаем текущий скрипт исполняемым на будущее
chmod +x "$0" 2>/dev/null

# Выход при любой ошибке
set -e

echo "=== 1. Установка PHP и необходимых расширений ==="
sudo apt install php php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-mysql -y

echo "=== 2. Настройка базы данных MySQL ==="
# Выполнение указанных SQL-команд для создания БД и пользователя
sudo mysql -e "CREATE DATABASE wordpress_db DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -e "CREATE USER 'wp_test'@'localhost' IDENTIFIED BY '0000';"
sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wp_test'@'localhost';"
sudo mysql -e "SET GLOBAL read_only = OFF;"
sudo mysql -e "SET GLOBAL super_read_only = OFF;"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "=== 3. Скачивание и распаковка WordPress ==="
cd /tmp
curl -L https://wordpress.org/latest.tar.gz -o latest.tar.gz
tar -xvf latest.tar.gz

echo "=== 4. Развертывание копий WordPress под порты балансировщика ==="
# Очищаем старые тестовые index.html страницы из конфигурации Apache2
sudo rm -rf /var/www/html/site_8080/*
sudo rm -rf /var/www/html/site_8081/*

# Копируем WordPress в директорию для порта 8080
sudo cp -a /tmp/wordpress/. /var/www/html/site_8080/

# Копируем WordPress в директорию для порта 8081 (аналог cp -r wordpress/ wordpress1/)
sudo cp -a /tmp/wordpress/. /var/www/html/site_8081/

echo "=== 5. Создание файлов конфигурации wp-config.php ==="
# Функция для генерации wp-config.php с поддержкой Reverse Proxy
configure_wp() {
    local TARGET_DIR=$1
    sudo cp "${TARGET_DIR}/wp-config-sample.php" "${TARGET_DIR}/wp-config.php"
    
    # Настройка параметров подключения к БД
    sudo sed -i "s/database_name_here/wordpress_db/g" "${TARGET_DIR}/wp-config.php"
    sudo sed -i "s/username_here/wp_test/g" "${TARGET_DIR}/wp-config.php"
    sudo sed -i "s/password_here/0000/g" "${TARGET_DIR}/wp-config.php"
    sudo sed -i "s/localhost/localhost/g" "${TARGET_DIR}/wp-config.php"
    
    # Важно: Добавляем код в начало wp-config.php, чтобы WordPress знал, 
    # что находится за реверс-прокси Nginx, иначе будут ломаться редиректы и стили CSS
    sudo sed -i "2i \\\n\$_SERVER['HTTP_HOST'] = '10.17.86.172';\nif (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) \&\& \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') { \$_SERVER['HTTPS'] = 'on'; }\nif (isset(\$_SERVER['HTTP_X_FORWARDED_FOR'])) { \$_SERVER['REMOTE_ADDR'] = \$_SERVER['HTTP_X_FORWARDED_FOR']; }\n" "${TARGET_DIR}/wp-config.php"
}

configure_wp "/var/www/html/site_8080"
configure_wp "/var/www/html/site_8081"

echo "=== 6. Выставление корректных прав и разрешений ==="
# Права для директории 8080
sudo chown -R www-data:www-data /var/www/html/site_8080
sudo find /var/www/html/site_8080/ -type d -exec chmod 755 {} \;
sudo find /var/www/html/site_8080/ -type f -exec chmod 644 {} \;

# Права для директории 8081
sudo chown -R www-data:www-data /var/www/html/site_8081
sudo find /var/www/html/site_8081/ -type d -exec chmod 755 {} \;
sudo find /var/www/html/site_8081/ -type f -exec chmod 644 {} \;

echo "=== 7. Перезапуск веб-серверов ==="
sudo systemctl restart apache2
sudo systemctl restart nginx

echo "=== Установка WordPress успешно завершена! ==="
echo "Откройте браузер и перейдите по адресу http://10.17.86.172 для настройки вашей CMS."
