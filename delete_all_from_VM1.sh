#!/bin/bash

# Скрипт для полного удаления nginx, apache2, mysql, wordpress, grafana, prometheus, filebeat
# ОС: Ubuntu 22.04
# Скрипт автоматически делает себя исполняемым при запуске

# Автоматически делаем текущий скрипт исполняемым
chmod +x "$0" 2>/dev/null

# Выход при критических ошибках окружения
set -e

echo "=== 1. Остановка запущенных сервисов ==="
sys_stop() {
    sudo systemctl stop "$1" 2>/dev/null || true
    sudo systemctl disable "$1" 2>/dev/null || true
}
sys_stop "nginx"
sys_stop "apache2"
sys_stop "mysql"
sys_stop "grafana-server"
sys_stop "prometheus"
sys_stop "filebeat"

echo "=== 2. Полное удаление пакетов из системы (Purge) ==="
# Команда purge удаляет бинарные файлы и системные конфигурации
sudo apt purge -y nginx nginx-common nginx-core \
                  apache2 apache2-utils apache2-bin apache2-data \
                  mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* \
                  grafana \
                  prometheus \
                  filebeat

# Удаление неиспользуемых зависимостей и очистка кэша пакетов
sudo apt autoremove -y
sudo apt clean

echo "=== 3. Принудительное удаление оставшихся директорий и конфигураций ==="
# Функция для безопасного удаления остаточных папок
remove_dir() {
    if [ -d "$1" ] || [ -f "$1" ]; then
        echo "Удаление: $1"
        sudo rm -rf "$1"
    fi
}

# Конфигурации в /etc
remove_dir "/etc/nginx"
remove_dir "/etc/apache2"
remove_dir "/etc/mysql"
remove_dir "/etc/grafana"
remove_dir "/etc/prometheus"
remove_dir "/etc/filebeat"

# Данные и логи в /var
remove_dir "/var/lib/nginx"
remove_dir "/var/lib/mysql"
remove_dir "/var/lib/grafana"
remove_dir "/var/lib/prometheus"
remove_dir "/var/lib/filebeat"
remove_dir "/var/log/nginx"
remove_dir "/var/log/apache2"
remove_dir "/var/log/mysql"
remove_dir "/var/log/grafana"
remove_dir "/var/log/prometheus"
remove_dir "/var/log/filebeat"

# Удаление WordPress и веб-директорий
remove_dir "/var/www/html"
remove_dir "/var/www/wordpress"

echo "=== 4. Очистка системных пользователей и групп ==="
sudo deluser --remove-home prometheus 2>/dev/null || true
sudo delgroup prometheus 2>/dev/null || true
sudo deluser grafana 2>/dev/null || true
sudo delgroup grafana 2>/dev/null || true

echo "=== Все указанные компоненты успешно удалены с VM1! ==="
