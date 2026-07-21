#!/bin/bash

# Скрипт для сбора конфигураций, скриптов и автоматической выгрузки на GitHub
# ОС: Ubuntu 22.04 | Репозиторий: https://github.com/AlexIridium/linux_VM1
# Скрипт автоматически делает себя исполняемым при запуске

# Делаем текущий скрипт исполняемым на будущее
chmod +x "$0" 2>/dev/null

# Выход при любой ошибке
set -e

# Переменные путей
BASE_SCRIPTS_DIR="/home/berd/scripts"
TARGET_GIT_DIR="/home/berd/scripts/linux_VM1_server1"
CONFIGS_DIR="$TARGET_GIT_DIR/configs_to_git"
REPO_URL="git@github.com:AlexIridium/linux_VM1_server1.git"

echo "=== 1. Создание структуры директорий ==="
mkdir -p "$CONFIGS_DIR"

echo "=== 2. Сбор основных системных конфигураций ==="
# Функция для безопасного копирования конфигураций (если они существуют)
copy_config() {
    local SRC=$1
    local DEST_NAME=$2
    if [ -e "$SRC" ]; then
        echo "Копирование конфигурации: $SRC -> $CONFIGS_DIR/$DEST_NAME"
        sudo cp -r "$SRC" "$CONFIGS_DIR/$DEST_NAME"
    else
        echo "Предупреждение: Путь $SRC не найден. Пропуск."
    fi
}

copy_config "/etc/apache2/" "apache2"
copy_config "/etc/nginx/" "nginx"
copy_config "/etc/filebeat/" "filebeat"
copy_config "/etc/mysql/" "mysql"
copy_config "/var/www/html/site_8080/wp-config.php" "wordpress_wp-config_8080.php"
copy_config "/var/www/html/site_8081/wp-config.php" "wordpress_wp-config_8081.php"
copy_config "/etc/grafana/" "grafana"
copy_config "/etc/prometheus/" "prometheus"

echo "=== 3. Копирование всех скриптов из $BASE_SCRIPTS_DIR ==="
# Находим все файлы в /home/berd/scripts/ и копируем их в корень репозитория,
# исключая саму папку linux_VM1_server1.
find "$BASE_SCRIPTS_DIR" -maxdepth 1 -type f -exec cp {} "$TARGET_GIT_DIR/" \;

# Корректируем права владельца, чтобы Git мог работать от пользователя berd без sudo
sudo chown -R berd:berd "$TARGET_GIT_DIR"

echo "=== 4. Инициализация Git и добавление в безопасные директории ==="
# Добавляем исключение безопасности для root, так как запуск идет через sudo, а владелец папки — berd
sudo git config --global --add safe.directory "$TARGET_GIT_DIR"

cd "$TARGET_GIT_DIR"

# Инициализируем репозиторий, если он не был инициализирован ранее
if [ ! -d ".git" ]; then
    sudo git init
    sudo git -c core.sshCommand="ssh -o StrictHostKeyChecking=no" remote add origin "$REPO_URL" || sudo git remote set-url origin "$REPO_URL"
    sudo git branch -M main
fi

# Добавляем все файлы в индекс Git
sudo git add .

echo "=== 5. Выгрузка файлов (Git Push) ==="
# Проверяем, есть ли изменения для коммита, чтобы скрипт не падал, если ничего не изменилось
if ! sudo git diff-index --quiet HEAD -- 2>/dev/null; then
    sudo git commit -m "Automated backup: configurations and server1 scripts update"
    # Используем SSH для отправки от имени root
    sudo git -c core.sshCommand="ssh -o StrictHostKeyChecking=no" push -u origin main --force
else
    echo "Изменений не обнаружено. Репозиторий Git уже синхронизирован."
fi

echo "=== Выгрузка на GitHub успешно завершена! ==="
