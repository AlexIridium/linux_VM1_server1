#!/bin/bash

# Скрипт для установки Git, создания бэкапа конфигураций и генерации SSH-ключа
# ОС: Ubuntu 22.04 | Имя: Alex | Email: berdnikow.ksit@mail.ru
# Скрипт автоматически делает себя исполняемым при запуске

# Делаем текущий скрипт исполняемым на будущее
chmod +x "$0" 2>/dev/null

# Выход при любой ошибке
set -e

# Переменные путей
GIT_DIR="/home/berd/scripts/configs_to_git"

echo "=== 1. Создание папки для конфигураций ==="
mkdir -p "$GIT_DIR"

echo "=== 2. Сбор и копирование конфигурационных файлов ==="

# Функция для безопасного копирования (если файл или папка существуют)
copy_config() {
    local SRC=$1
    local DEST_NAME=$2
    if [ -e "$SRC" ]; then
        echo "Копирование конфигурации: $SRC -> $GIT_DIR/$DEST_NAME"
        sudo cp -r "$SRC" "$GIT_DIR/$DEST_NAME"
    else
        echo "Предупреждение: Путь $SRC не найден. Пропуск."
    fi
}

# Копируем конфигурации согласно списку
copy_config "/etc/apache2/" "apache2"
copy_config "/etc/nginx/" "nginx"
copy_config "/etc/filebeat/" "filebeat"
copy_config "/etc/mysql/" "mysql"
copy_config "/var/www/html/site_8080/wp-config.php" "wordpress_wp-config_8080.php"
copy_config "/var/www/html/site_8081/wp-config.php" "wordpress_wp-config_8081.php"
copy_config "/etc/grafana/" "grafana"
copy_config "/etc/prometheus/" "prometheus"

# Назначаем права пользователю berd на скопированные файлы
sudo chown -R berd:berd "/home/berd/scripts"

echo "=== 3. Установка Git ==="
sudo apt install git -y

echo "=== 4. Настройка глобальных параметров Git ==="
git config --global user.name "Alex"
git config --global user.email "berdnikow.ksit@mail.ru"

echo "=== Текущие настройки Git ==="
git config --list

echo "=== 5. Генерация SSH-ключа Ed25519 для пользователя root ==="
# Генерируем ключ без пароля (passphrase) и без интерактивных запросов
if [ ! -f /root/.ssh/id_ed25519 ]; then
    sudo ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
else
    echo "SSH-ключ уже существует."
fi

echo "=== 6. ПУБЛИЧНЫЙ SSH-КЛЮЧ ДЛЯ GitHub/GitLab ==="
echo "Скопируйте этот ключ целиком:"
echo "-----------------------------------------------------------------"
sudo cat /root/.ssh/id_ed25519.pub
echo "-----------------------------------------------------------------"

echo "=== Установка и настройка успешно завершены! ==="
