#!/bin/bash

# Скрипт для полного удаления Grafana, Prometheus, Node Exporter и prometheus-node
# ОС: Ubuntu 22.04
# Скрипт автоматически делает себя исполняемым при запуске

# Автоматически делаем текущий скрипт исполняемым
chmod +x "$0" 2>/dev/null

# Выход при критических ошибках
set -e

echo "=== 1. Остановка и отключение служб ==="
sys_stop() {
    sudo systemctl stop "$1" 2>/dev/null || true
    sudo systemctl disable "$1" 2>/dev/null || true
}
sys_stop "grafana-server"
sys_stop "prometheus"
sys_stop "node_exporter"
sys_stop "prometheus-node-exporter"

echo "=== 2. Полное удаление установленных пакетов (Purge) ==="
# Удаляем пакеты вместе с конфигурациями из репозитория apt
sudo apt purge -y grafana prometheus prometheus-node-exporter 2>/dev/null || true

# Очистка неиспользуемых зависимостей и кэша apt
sudo apt autoremove -y
sudo apt clean

echo "=== 3. Удаление остаточных директорий, конфигураций и логов ==="
remove_file_or_dir() {
    if [ -d "$1" ] || [ -f "$1" ]; then
        echo "Удаление: $1"
        sudo rm -rf "$1"
    fi
}

# Очистка Grafana
remove_file_or_dir "/etc/grafana"
remove_file_or_dir "/var/lib/grafana"
remove_file_or_dir "/var/log/grafana"
remove_file_or_dir "/usr/share/grafana"

# Очистка Prometheus
remove_file_or_dir "/etc/prometheus"
remove_file_or_dir "/var/lib/prometheus"
remove_file_or_dir "/var/log/prometheus"

# Очистка Node Exporter (как из apt-пакета, так и ручной установки из tar.gz)
remove_file_or_dir "/etc/prometheus-node-exporter"
remove_file_or_dir "/var/lib/prometheus-node-exporter"
remove_file_or_dir "/var/log/prometheus-node-exporter"
remove_file_or_dir "/usr/local/bin/node_exporter"
remove_file_or_dir "/etc/systemd/system/node_exporter.service"
remove_file_or_dir "/etc/node_exporter"

# Перезапускаем демон systemd, чтобы сбросить кэш удаленных служб
sudo systemctl daemon-reload

echo "=== 4. Удаление системных пользователей и групп ==="
sudo deluser --remove-home prometheus 2>/dev/null || true
sudo delgroup prometheus 2>/dev/null || true
sudo deluser grafana 2>/dev/null || true
sudo delgroup grafana 2>/dev/null || true
sudo deluser node_exporter 2>/dev/null || true
sudo delgroup node_exporter 2>/dev/null || true
sudo deluser prometheus-node-exporter 2>/dev/null || true
sudo delgroup prometheus-node-exporter 2>/dev/null || true

echo "=== Все компоненты мониторинга, включая prometheus-node, успешно удалены! ==="
