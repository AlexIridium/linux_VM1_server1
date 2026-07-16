#!/bin/bash

# Скрипт для автоматической установки и настройки MySQL 8.0 (Master)
# ОС: Ubuntu 22.04 | IP: 10.17.86.172
# Скрипт автоматически делает себя исполняемым при запуске

# Делаем текущий скрипт исполняемым на будущее
chmod +x "$0" 2>/dev/null

# Выход при любой ошибке
set -e

echo "=== 1. Установка MySQL 8.0 ==="
sudo apt install -y mysql-server

echo "=== 2. Настройка конфигурационного файла mysqld.cnf ==="
CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Резервная копия оригинального конфига
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Изменение bind-address для разрешения внешних подключений
sudo sed -i 's/^bind-address.*/bind-address            = 0.0.0.0/' "$CONFIG_FILE"
sudo sed -i 's/^mysqlx-bind-address.*/mysqlx-bind-address     = 0.0.0.0/' "$CONFIG_FILE"

# Добавление параметров репликации в секцию [mysqld]
sudo bash -c "cat >> $CONFIG_FILE" << 'EOF'

# --- Настройки MySQL Master для репликации ---
server-id                = 1
log-bin                  = mysql-bin
binlog_format            = row
gtid-mode                = ON
enforce-gtid-consistency  = ON
log-replica-updates      = ON
EOF

echo "=== 3. Перезапуск службы MySQL ==="
sudo systemctl restart mysql
sudo systemctl enable mysql

echo "=== 4. Создание пользователя репликации ==="
# Ожидание готовности СУБД к приему команд
sleep 3

# Выполнение SQL-команд
sudo mysql -e "CREATE USER 'wp_test'@'%' IDENTIFIED WITH 'caching_sha2_password' BY '0000';"
sudo mysql -e "GRANT REPLICATION SLAVE ON *.* TO 'wp_test'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "=== 5. Проверка статуса ==="
sudo systemctl is-active mysql

echo "=== Установка, настройка Master-сервера и создание пользователя успешно завершены! ==="
