#!/bin/bash

# Проверка на права root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root / Пожалуйста, запустите от имени root (sudo -i)"
  exit 1
fi

# Путь к локальной базе настроек скрипта
CONFIG_FILE="/opt/remnatools/config.conf"
VERSION="v1.4.0" # Текущая версия скрипта
UPDATE_URL="https://raw.githubusercontent.com/ImFraGushka/RemnaTools/main/RWTools.sh" # URL для обновления скрипта
IPV6_SCRIPT_PATH="/opt/remnatools/utils/ipv6_toggle.sh" # Локальный кэш скрипта переключения IPv6
IPV6_SCRIPT_URL="https://raw.githubusercontent.com/ImFraGushka/RemnaTools/main/utils/ipv6_toggle.sh" # URL для загрузки скрипта переключения IPv6
NODE_ACCELERATOR_PATH="/opt/remnatools/node-accelerator" # Локальный кэш директории node-accelerator
NODE_ACCELERATOR_REPO="https://github.com/ImFraGushka/RemnaTools.git" # Репозиторий для загрузки node-accelerator
TRAFFIC_GUARD_INSTALL_URL="https://raw.githubusercontent.com/dotX12/traffic-guard/master/install.sh" # Установщик TrafficGuard (защита от сканеров портов)
TRAFFIC_GUARD_DEFAULT_LISTS=(
    "https://raw.githubusercontent.com/shadow-netlab/traffic-guard-lists/refs/heads/main/public/antiscanner.list"
    "https://raw.githubusercontent.com/shadow-netlab/traffic-guard-lists/refs/heads/main/public/government_networks.list"
) # Списки подсетей по умолчанию (https://github.com/shadow-netlab/traffic-guard-lists)
mkdir -p /opt/remnatools

# --- ФУНКЦИЯ УДАЛЕНИЯ СКРИПТА ---
uninstall_script() {
    clear
    local title="Удаление RemnaTools..."
    local confirm_msg="Вы уверены, что хотите полностью удалить RemnaTools? (y/n): "
    local del_bin="Удаление скрипта из /usr/local/bin/rwtools..."
    local del_alias="Удаление алиасов из .bashrc и .zshrc..."
    local success="✓ RemnaTools успешно удален!"
    local cancel="Удаление отменено."
    local back="Нажмите Enter для возврата..."
    
    if [ "$RLANG" == "EN" ]; then
        title="Uninstalling RemnaTools..."
        confirm_msg="Are you sure you want to completely uninstall RemnaTools? (y/n): "
        del_bin="Removing script from /usr/local/bin/rwtools..."
        del_alias="Removing aliases from .bashrc and .zshrc..."
        success="✓ RemnaTools uninstalled successfully!"
        cancel="Uninstallation cancelled."
        back="Press Enter to return..."
    fi

    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m           $title                 \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""
    read -p "$confirm_msg" CONFIRM
    
    if [[ "$CONFIRM" =~ ^[YyДд]$ ]]; then
        echo "$del_bin"
        sudo rm -f /usr/local/bin/rwtools
        
        echo "$del_alias"
        [ -f ~/.bashrc ] && sed -i 's/^alias rwtools=.*$//' ~/.bashrc && sed -i '/^$/N;/\n$/N;/\n\n/D' ~/.bashrc
        [ -f ~/.zshrc ] && sed -i 's/^alias rwtools=.*$//' ~/.zshrc && sed -i '/^$/N;/\n$/N;/\n\n/D' ~/.zshrc
        
        echo -e "\e[1;32m$success\e[0m"
    else
        echo "$cancel"
    fi
    read -p "$back"
}

# --- ЗАГРУЗКА КОНФИГА ---
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Читаем только валидные переменные (без дефисов в именах), чтобы избежать ошибок Bash
        while IFS='=' read -r key value; do
            if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                # Убираем кавычки из значения
                val="${value%\"}"
                val="${val#\"}"
                export "$key"="$val"
            fi
        done < "$CONFIG_FILE"
    fi
    # Дефолтные значения, если настроек нет
    PANEL_URL=${PANEL_URL:-""}
    API_TOKEN=${API_TOKEN:-""}
    TG_TOKEN=${TG_TOKEN:-""}
    TG_CHAT_ID=${TG_CHAT_ID:-""}
    TG_TOPIC_ID=${TG_TOPIC_ID:-""}
    CRON_CHOICE=${CRON_CHOICE:-""}
    USER_TIME=${USER_TIME:-""}
    RLANG=${RLANG:-""} # Переменная для языка
}

# Функция сохранения параметров
save_config() {
    cat <<EOF > "$CONFIG_FILE"
PANEL_URL="$PANEL_URL"
API_TOKEN="$API_TOKEN"
TG_TOKEN="$TG_TOKEN"
TG_CHAT_ID="$TG_CHAT_ID"
TG_TOPIC_ID="$TG_TOPIC_ID"
CRON_CHOICE="$CRON_CHOICE"
USER_TIME="$USER_TIME"
RLANG="$RLANG"
EOF
}

# Функция выбора языка
choose_language() {
    if [ -z "$RLANG" ]; then
        clear
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m       Select Language / Выберите язык            \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        echo "1) English"
        echo "2) Русский"
        read -p "Choice / Выбор (1-2): " LANG_CHOICE
        
        if [ "$LANG_CHOICE" == "2" ]; then
            RLANG="RU"
        else
            RLANG="EN"
        fi
        save_config
    fi
}

# Функция смены языка (через меню)
change_language_menu() {
    RLANG="" # Сбрасываем текущий язык
    choose_language
    echo -e "\e[1;32m Language changed / Язык изменен!\e[0m"
    sleep 1
}

# Функция "О нас"
show_about() {
    clear
    if [ "$RLANG" == "RU" ]; then
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m                  🚀 RemnaTools $VERSION             \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;33m📋 Описание:\e[0m"
        echo -e "   Ультимативный CLI-инструмент для управления"
        echo -e "   экосистемой Remnawave на Linux/Ubuntu серверах."
        echo -e ""
        echo -e "\e[1;33m✨ Основные возможности:\e[0m"
        echo -e "   ✓ Автоустановка Панели (Caddy + PostgreSQL + Docker)"
        echo -e "   ✓ Автоустановка Ноды (с BBR3, IPv6-off, SelfSteal)"
        echo -e "   ✓ Управление автоматическими бэкапами"
        echo -e "   ✓ Быстрое восстановление из бэкапа"
        echo -e "   ✓ Сборник тестов и бенчмарков для Linux-серверов"
        echo -e ""
        echo -e "\e[1;33m📱 Поддерживаемые системы:\e[0m"
        echo -e "   Ubuntu 18.04+ • Debian 10+"
    else
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m                  🚀 RemnaTools $VERSION             \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;33m📋 Description:\e[0m"
        echo -e "   Ultimate CLI tool for managing the"
        echo -e "   Remnawave ecosystem on Linux/Ubuntu servers."
        echo -e ""
        echo -e "\e[1;33m✨ Key Features:\e[0m"
        echo -e "   ✓ Auto-install Panel (Caddy + PostgreSQL + Docker)"
        echo -e "   ✓ Auto-install Node (with BBR3, IPv6-off, SelfSteal)"
        echo -e "   ✓ Automatic Backup Management"
        echo -e "   ✓ Fast Backup Restoration"
        echo -e "   ✓ Test & Benchmark collection for Linux servers"
        echo -e ""
        echo -e "\e[1;33m📱 Supported Systems:\e[0m"
        echo -e "   Ubuntu 18.04+ • Debian 10+"
    fi
    echo -e ""
    echo -e "\e[1;36m====================================================\e[0m"
}

# Функция обновления
update_script() {
    clear
    local title="Обновление RemnaTools..."
    local msg_loading="Загрузка последней версии с GitHub..."
    local err_empty="✗ Ошибка: Скачанный файл пуст."
    local err_syntax="✗ Ошибка: Скачанный файл содержит синтаксические ошибки."
    local err_copy="✗ Ошибка при копировании файла."
    local err_load="✗ Ошибка при загрузке: проверьте интернет-соединение."
    local msg_ok="✓ Скрипт успешно обновлен!"
    local msg_restart="  Перезапустите скрипт для применения изменений."

    if [ "$RLANG" == "EN" ]; then
        title="Updating RemnaTools..."
        msg_loading="Loading latest version from GitHub..."
        err_empty="✗ Error: Downloaded file is empty."
        err_syntax="✗ Error: Downloaded file contains syntax errors."
        err_copy="✗ Error while copying file."
        err_load="✗ Error during download: check your internet connection."
        msg_ok="✓ Script updated successfully!"
        msg_restart="  Restart the script to apply changes."
    fi

    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m           $title                 \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo "$msg_loading"
    
    # Определяем путь к текущему исполняемому файлу
    SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")
    
    # Загружаем новую версию во временный файл
    local TMP_FILE
    TMP_FILE=$(mktemp)
    
    # Устанавливаем "ловушку" для удаления временного файла при любом выходе из скрипта (даже при Ctrl+C)
    trap 'rm -f "$TMP_FILE"' EXIT
    
    if curl -fsSL "$UPDATE_URL" -o "$TMP_FILE"; then
        # Проверяем, не пустой ли файл скачался
        if [ ! -s "$TMP_FILE" ]; then
            echo -e "\e[1;31m$err_empty\e[0m"
            return 1
        fi
        
        # Проверяем синтаксис скачанного файла перед заменой
        if ! bash -n "$TMP_FILE"; then
            echo -e "\e[1;31m$err_syntax\e[0m"
            return 1
        fi
        
        # Создаем резервную копию текущего скрипта
        BACKUP_PATH="$SCRIPT_PATH.bak"
        sudo cp "$SCRIPT_PATH" "$BACKUP_PATH"
        
        # Обновляем основной файл
        if sudo cp "$TMP_FILE" "$SCRIPT_PATH"; then
            sudo chmod +x "$SCRIPT_PATH"
            # Если скрипт установлен в /usr/local/bin, обновляем и там
            if [ "$SCRIPT_PATH" != "/usr/local/bin/rwtools" ] && [ -f /usr/local/bin/rwtools ]; then
                sudo cp "$TMP_FILE" /usr/local/bin/rwtools
                sudo chmod +x /usr/local/bin/rwtools
            fi
            echo -e "\e[1;32m$msg_ok\e[0m"
            echo "$msg_restart"
            exit 0 # При успехе выходим. trap позаботится об удалении файла.
        else
            echo -e "\e[1;31m$err_copy\e[0m"
            sudo mv "$BACKUP_PATH" "$SCRIPT_PATH" # Восстанавливаем из бэкапа
        fi
    else
        echo -e "\e[1;31m$err_load\e[0m"
        return 1
    fi
}

# --- ФУНКЦИЯ ОЖИДАНИЯ APT LOCK ---
wait_for_apt_lock() {
    local msg_wait="Ожидание освобождения apt-lock (может занять несколько минут)..."
    if [ "$RLANG" == "EN" ]; then
        msg_wait="Waiting for apt-lock to be released (may take a few minutes)..."
    fi

    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
       echo "$msg_wait"
       sleep 3
    done
}

# --- ФУНКЦИЯ ПРОВЕРКИ И УСТАНОВКИ ЗАВИСИМОСТЕЙ ---
install_dependencies() {
    local packages_to_install=()
    local dependencies=("curl" "wget" "git" "tar" "openssl" "nftables" "fuser")
    
    # Интернационализация сообщений
    local msg_checking="Проверка зависимостей..."
    local msg_installing="Установка недостающих пакетов:"
    local msg_docker_prompt="Docker не найден. Он необходим для работы Панели и Ноды. Установить Docker? (y/n): "
    local msg_docker_installing="Установка Docker..."
    local msg_docker_ok="✓ Docker успешно установлен."
    local msg_docker_skip="Установка Docker пропущена."
    local msg_all_ok="✓ Все зависимости установлены."

    if [ "$RLANG" == "EN" ]; then
        msg_checking="Checking dependencies..."
        msg_installing="Installing missing packages:"
        msg_docker_prompt="Docker not found. It is required for the Panel and Node to work. Install Docker? (y/n): "
        msg_docker_installing="Installing Docker..."
        msg_docker_ok="✓ Docker installed successfully."
        msg_docker_skip="Docker installation skipped."
        msg_all_ok="✓ All dependencies are installed."
    fi

    echo "$msg_checking"
    
    # Проверяем наличие каждого пакета
    for pkg in "${dependencies[@]}"; do
        if ! command -v $pkg &> /dev/null; then
            packages_to_install+=($pkg)
        fi
    done
    
    # Если есть что установить
    if [ ${#packages_to_install[@]} -ne 0 ]; then
        echo "$msg_installing ${packages_to_install[*]}"
        wait_for_apt_lock
        apt-get update
        apt-get install -y "${packages_to_install[@]}"
    fi

    # Отдельно проверяем Docker
    if ! command -v docker &> /dev/null; then
        read -p "$msg_docker_prompt" INSTALL_DOCKER
        if [[ "$INSTALL_DOCKER" =~ ^[YyДд]$ ]]; then
            echo "$msg_docker_installing"
            curl -fsSL https://get.docker.com | sh
            echo -e "\e[1;32m$msg_docker_ok\e[0m"
        else
            echo "$msg_docker_skip"
        fi
    fi
    
    echo -e "\e[1;32m$msg_all_ok\e[0m"
}

# Инициализируем конфиг при старте
load_config
choose_language

# Флаг --about
if [ "$1" == "--about" ]; then
    show_about
    exit 0
fi

# Флаг --update
if [ "$1" == "--update" ]; then
    update_script
    exit 0
fi

# Флаг --install (установка rwtools команды)
if [ "$1" == "--install" ]; then
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m    Установка команды rwtools в систему...        \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    
    # 1. Устанавливаем зависимости
    install_dependencies
    
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/RWTools.sh"
    
    # 2. Копируем скрипт в /usr/local/bin
    echo "Копирование скрипта в /usr/local/bin/rwtools..."
    sudo cp "$SCRIPT_PATH" /usr/local/bin/rwtools
    sudo chmod +x /usr/local/bin/rwtools
    
    # 3. Создаем алиас
    echo "Добавление алиаса в .bashrc и .zshrc..."
    if [ -f ~/.bashrc ]; then
        if ! grep -q "alias rwtools=" ~/.bashrc; then
            echo "alias rwtools='sudo rwtools'" >> ~/.bashrc
        fi
    fi
    if [ -f ~/.zshrc ]; then
        if ! grep -q "alias rwtools=" ~/.zshrc; then
            echo "alias rwtools='sudo rwtools'" >> ~/.zshrc
        fi
    fi
    
    echo -e "\e[1;32m✓ Команда установлена!\e[0m"
    echo "  Используйте: rwtools"
    echo "  или: sudo rwtools"
    exit 0
fi

# --- ФУНКЦИИ УСТАНОВКИ ---

install_panel() {
    clear
    echo "=== Запуск установки Панели ==="
    echo "Select language / Выберите язык:"
    echo "1) English"
    echo "2) Русский"
    read -p "Choice / Выбор (1-2): " LANG_CHOICE

    if [ "$LANG_CHOICE" == "2" ]; then LANG="RU"; else LANG="EN"; fi

    if [ "$LANG" == "RU" ]; then
        MSG_DOMAIN="Введите FRONT_END_DOMAIN (например, panel.example.com): "
        MSG_SUB="Введите SUB_PUBLIC_DOMAIN (например, sub.example.com): "
        MSG_DOCKER_CHECK="Проверка Docker..."
        MSG_DOCKER_EXISTS="✓ Docker уже установлен."
        MSG_DOCKER_INSTALL="Docker не найден. Установка..."
    else
        MSG_DOMAIN="Enter FRONT_END_DOMAIN (e.g., panel.example.com): "
        MSG_SUB="Enter SUB_PUBLIC_DOMAIN (e.g., sub.example.com): "
        MSG_DOCKER_CHECK="Checking Docker..."
        MSG_DOCKER_EXISTS="✓ Docker is already installed."
        MSG_DOCKER_INSTALL="Docker not found. Installing..."
    fi

    read -p "$MSG_DOMAIN" FRONT_END_DOMAIN
    read -p "$MSG_SUB" SUB_PUBLIC_DOMAIN

    echo "$MSG_DOCKER_CHECK"
    if ! command -v docker &> /dev/null; then
        echo "$MSG_DOCKER_INSTALL"
        curl -fsSL https://get.docker.com | sh
    else
        echo -e "\e[1;32m$MSG_DOCKER_EXISTS\e[0m"
    fi
    
    mkdir -p /opt/remnawave && cd /opt/remnawave
    curl -o docker-compose.yml https://raw.githubusercontent.com/remnawave/backend/refs/heads/main/docker-compose-prod.yml
    curl -o .env https://raw.githubusercontent.com/remnawave/backend/refs/heads/main/.env.sample

    sed -i "s/^JWT_AUTH_SECRET=.*/JWT_AUTH_SECRET=$(openssl rand -hex 64)/" .env
    sed -i "s/^JWT_API_TOKENS_SECRET=.*/JWT_API_TOKENS_SECRET=$(openssl rand -hex 64)/" .env
    sed -i "s/^METRICS_PASS=.*/METRICS_PASS=$(openssl rand -hex 64)/" .env
    sed -i "s/^WEBHOOK_SECRET_HEADER=.*/WEBHOOK_SECRET_HEADER=$(openssl rand -hex 64)/" .env

    pw=$(openssl rand -hex 24)
    sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$pw/" .env
    sed -i "s|^\(DATABASE_URL=\"postgresql://postgres:\)[^\@]*\(@.*\)|\1$pw\2|" .env
    sed -i "s|^FRONT_END_DOMAIN=.*|FRONT_END_DOMAIN=\"https:\/\/$FRONT_END_DOMAIN\"|" .env
    sed -i "s|^SUB_PUBLIC_DOMAIN=.*|SUB_PUBLIC_DOMAIN=\"$SUB_PUBLIC_DOMAIN\"|" .env

    docker compose up -d

    mkdir -p /opt/remnawave/caddy && cd /opt/remnawave/caddy
    cat <<EOF > Caddyfile
https://$FRONT_END_DOMAIN {
        reverse_proxy * http://remnawave:3000
}
:443 {
    tls internal
    respond 204
}
EOF

    cat <<EOF > docker-compose.yml
services:
    caddy:
        image: caddy:2.9
        container_name: 'caddy'
        hostname: caddy
        restart: always
        ports:
            - '0.0.0.0:443:443'
            - '0.0.0.0:80:80'
        networks:
            - remnawave-network
        volumes:
            - ./Caddyfile:/etc/caddy/Caddyfile
            - caddy-ssl-data:/data
networks:
    remnawave-network:
        name: remnawave-network
        driver: bridge
        external: true
volumes:
    caddy-ssl-data:
        driver: local
        external: false
        name: caddy-ssl-data
EOF
    docker compose up -d
    echo "Панель успешно установлена!"
    read -p "Нажмите Enter для возврата..."
}

install_node() {
    clear
    export LANG=en_US.UTF-8

    # --- Мультиязычный блок текста ---
    declare -A MSG

    echo "Select language / Выберите язык:"
    echo "1) English"
    echo "2) Русский"
    read -p "Choice / Выбор (1-2): " LANG_CHOICE
    
    if [ "$LANG_CHOICE" == "2" ]; then
        MSG[welcome]="=== Установка Remnawave Node ==="
        MSG[ask_node_port]="Введите внутренний порт ноды [по умолчанию: 2222]: "
        MSG[ask_secret]="Введите секретный ключ ноды (Secret Key): "
        MSG[ask_bbr3]="Хотите установить BBR3? (y/n): "
        MSG[ask_ipv6]="Хотите отключить IPv6? (y/n): "
        MSG[ask_ss_enable]="Хотите настроить SelfSteal (Caddy)? (y/n): "
        MSG[ask_domain]="Введите домен для SelfSteal (например, node.example.com): "
        MSG[ask_ss_port]="Введите порт для SelfSteal [по умолчанию: 9443]: "
        MSG[updating]="[1/7] Обновление системы..."
        MSG[enabling_bbr]="[2/7] Включение стандартного BBR..."
        MSG[installing_bbr3]="Установка BBR3..."
        MSG[installing_docker]="[3/7] Проверка и установка Docker..."
        MSG[docker_exists]="Docker уже установлен, пропускаем этот шаг."
        MSG[conf_node]="[4/7] Настройка Remnawave Node..."
        MSG[conf_selfsteal]="[5/7] Настройка SelfSteal (Caddy)..."
        MSG[conf_html]="[6/7] Создание заглушки index.html..."
        MSG[running_containers]="[7/7] Запуск контейнеров..."
        MSG[disabling_ipv6]="[Финал] Отключение IPv6..."
        MSG[success]="Установка успешно завершена!"
        MSG[err_empty]="Ошибка: Поле не может быть пустым."
    else
        MSG[welcome]="=== Remnawave Node Installation ==="
        MSG[ask_node_port]="Enter internal node port [default: 2222]: "
        MSG[ask_secret]="Enter node Secret Key: "
        MSG[ask_bbr3]="Do you want to install BBR3? (y/n): "
        MSG[ask_ipv6]="Do you want to disable IPv6? (y/n): "
        MSG[ask_ss_enable]="Do you want to configure SelfSteal (Caddy)? (y/n): "
        MSG[ask_domain]="Enter domain for SelfSteal (e.g., node.example.com): "
        MSG[ask_ss_port]="Enter port for SelfSteal [default: 9443]: "
        MSG[updating]="[1/7] Updating system packages..."
        MSG[enabling_bbr]="[2/7] Enabling standard BBR..."
        MSG[installing_bbr3]="Installing BBR3..."
        MSG[installing_docker]="[3/7] Checking and installing Docker..."
        MSG[docker_exists]="Docker is already installed, skipping this step."
        MSG[conf_node]="[4/7] Configuring Remnawave Node..."
        MSG[conf_selfsteal]="[5/7] Configuring SelfSteal (Caddy)..."
        MSG[conf_html]="[6/7] Creating index.html template..."
        MSG[running_containers]="[7/7] Starting containers..."
        MSG[disabling_ipv6]="[Final] Disabling IPv6..."
        MSG[success]="Installation completed successfully!"
        MSG[err_empty]="Error: Field cannot be empty."
    fi

    clear
    echo "${MSG[welcome]}"
    echo "============================================="

    # --- Сбор обязательных данных для Ноды ---
    read -p "${MSG[ask_node_port]}" NODE_PORT
    NODE_PORT=${NODE_PORT:-2222}

    read -p "${MSG[ask_secret]}" SECRET_KEY
    if [ -z "$SECRET_KEY" ]; then echo "${MSG[err_empty]}"; return 1; fi

    # --- Запрос опциональных системных настроек ---
    read -p "${MSG[ask_bbr3]}" WANT_BBR3
    read -p "${MSG[ask_ipv6]}" WANT_IPV6

    # --- Запрос настройки SelfSteel ---
    read -p "${MSG[ask_ss_enable]}" WANT_SELFSTEAL

    if [[ "$WANT_SELFSTEAL" =~ ^[YyДд]$ ]]; then
        read -p "${MSG[ask_domain]}" SELF_STEAL_DOMAIN
        if [ -z "$SELF_STEAL_DOMAIN" ]; then echo "${MSG[err_empty]}"; return 1; fi

        read -p "${MSG[ask_ss_port]}" SELF_STEAL_PORT
        SELF_STEAL_PORT=${SELF_STEAL_PORT:-9443}
    fi

    echo "============================================="

    # 1. Обновление системы
    echo "${MSG[updating]}"
    wait_for_apt_lock
    apt update && apt upgrade -y

    # 2. Включение базового BBR
    echo "${MSG[enabling_bbr]}"
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p

    # Опционально: BBR3
    if [[ "$WANT_BBR3" =~ ^[YyДд]$ ]]; then
        echo "${MSG[installing_bbr3]}"
        bash <(curl -sSL https://raw.githubusercontent.com/ivan-nginx/bbr3/main/optimize_network.sh)
    fi

    # 3. Проверка и установка Docker
    echo "${MSG[installing_docker]}"
    if command -v docker &> /dev/null; then
        echo "${MSG[docker_exists]}"
    else
        sudo curl -fsSL https://get.docker.com | sh
    fi

    # 4. Настройка Remnawave Node
    echo "${MSG[conf_node]}"
    mkdir -p /opt/remnanode && cd /opt/remnanode

    cat <<EOF > docker-compose.yml
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    environment:
      - NODE_PORT=${NODE_PORT}
      - SECRET_KEY="${SECRET_KEY}"
EOF

    docker compose up -d

    # 5. Опциональная настройка SelfSteel (Caddy)
    if [[ "$WANT_SELFSTEAL" =~ ^[YyДд]$ ]]; then
        echo "${MSG[conf_selfsteal]}"
        mkdir -p /opt/selfsteel && cd /opt/selfsteel

        cat <<'EOF' > Caddyfile
{
    https_port {$SELF_STEAL_PORT}
    default_bind 127.0.0.1
    servers {
        listener_wrappers {
            proxy_protocol {
                allow 127.0.0.1/32
            }
            tls
        }
    }
    auto_https disable_redirects
}

http://{$SELF_STEAL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$SELF_STEAL_DOMAIN}{uri} permanent
}

https://{$SELF_STEAL_DOMAIN} {
    root * /var/www/html
    try_files {path} /index.html
    file_server
}

:{$SELF_STEAL_PORT} {
    tls internal
    respond 204
}

:80 {
    bind 0.0.0.0
    respond 204
}
EOF

        cat <<EOF > .env
SELF_STEAL_DOMAIN=${SELF_STEAL_DOMAIN}
SELF_STEAL_PORT=${SELF_STEAL_PORT}
EOF

        cat <<EOF > docker-compose.yml
services:
  caddy:
    image: caddy:latest
    container_name: caddy-remnawave
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ../html:/var/www/html
      - ./logs:/var/log/caddy
      - caddy_data_selfsteal:/data
      - caddy_config_selfsteal:/config
    env_file:
      - .env
    network_mode: "host"

volumes:
  caddy_data_selfsteal:
  caddy_config_selfsteal:
EOF

        # 6. Создание HTML сайта-заглушки
        echo "${MSG[conf_html]}"
        mkdir -p /opt/html && cd /opt/html

        cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My Website</title>
</head>
<body>
    <h1>Welcome to My Website</h1>
    <p>This is the homepage.</p>
</body>
</html>
EOF

        # 7. Запуск контейнеров SelfSteel
        echo "${MSG[running_containers]}"
        cd /opt/selfsteel
        docker compose up -d
    fi

    # [Последняя очередь] Опционально: Отключение IPv6
    if [[ "$WANT_IPV6" =~ ^[YyДд]$ ]]; then
        echo "${MSG[disabling_ipv6]}"
        cat <<EOF >> /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
        sysctl -p
    fi

    echo "============================================="
    echo -e "\033[0;32m${MSG[success]}\033[0m"
    echo "Remnanode Port: $NODE_PORT"
    if [[ "$WANT_SELFSTEAL" =~ ^[YyДд]$ ]]; then
        echo "SelfSteal Domain: $SELF_STEAL_DOMAIN"
        echo "SelfSteal Port: $SELF_STEAL_PORT"
    fi
    echo "============================================="
    read -p "Нажмите Enter для возврата..."
}

# --- БЛОК БЭКАПОВ ---

create_backup_now() {
    clear
    local title="Создание резервной копии..."
    local err_no_tg="✗ Ошибка: Telegram не настроен!"
    local msg_goto_conf="  Перейдите в Управление бэкапами → Настройка автоотправки"
    local back="Нажмите Enter для возврата..."
    local msg_archiving="Архивирование данных..."
    local msg_size="Размер: "
    local msg_sending="Отправка в Telegram..."
    local msg_ok="✓ Бэкап успешно создан и отправлен!"
    local msg_err_arch="✗ Ошибка при создании архива!"
    
    if [ "$RLANG" == "EN" ]; then
        title="Creating Backup..."
        err_no_tg="✗ Error: Telegram not configured!"
        msg_goto_conf="  Go to Backup Management → Configure Auto-send"
        back="Press Enter to return..."
        msg_archiving="Archiving data..."
        msg_size="Size: "
        msg_sending="Sending to Telegram..."
        msg_ok="✓ Backup created and sent successfully!"
        msg_err_arch="✗ Error creating archive!"
    fi

    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m            $title            \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    
    if [ -z "$TG_TOKEN" ] || [ -z "$TG_CHAT_ID" ]; then
        echo -e "\e[1;31m$err_no_tg\e[0m"
        echo "$msg_goto_conf"
        read -p "$back"
        return 1
    fi
    
    BACKUP_NAME="remna_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    BACKUP_DIR="/tmp/remna_backups"
    
    mkdir -p $BACKUP_DIR
    echo "$msg_archiving"
    tar -czf $BACKUP_DIR/$BACKUP_NAME -C / opt/remnawave opt/remnanode 2>/dev/null
    
    if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
        echo "$msg_size$(du -h $BACKUP_DIR/$BACKUP_NAME | cut -f1)"
        echo "$msg_sending"
        
        if [ -z "$TG_TOPIC_ID" ]; then
            curl -s -F chat_id="$TG_CHAT_ID" -F document=@"$BACKUP_DIR/$BACKUP_NAME" \
                https://api.telegram.org/bot$TG_TOKEN/sendDocument >/dev/null 2>&1
        else
            curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_TOPIC_ID" \
                -F document=@"$BACKUP_DIR/$BACKUP_NAME" \
                https://api.telegram.org/bot$TG_TOKEN/sendDocument >/dev/null 2>&1
        fi
        
        rm -rf $BACKUP_DIR
        echo -e "\e[1;32m$msg_ok\e[0m"
    else
        echo -e "\e[1;31m$msg_err_arch\e[0m"
    fi
    
    read -p "$back"
}

configure_backup_auto() {
    clear
    local title="Настройка автоматической отправки бэкапов"
    local ask_token="Введите Telegram Bot Token: "
    local ask_chat="Введите Telegram Chat ID: "
    local ask_topic="Введите Topic ID (оставьте пустым если нет): "
    local ask_cron_title="Выберите периодичность бэкапов:"
    local cron_opt1="Раз в час (0 * * * *)"
    local cron_opt2="Раз в день в полночь (0 0 * * *)"
    local cron_opt3="Точечное время (введу вручную)"
    local ask_schedule="Выберите расписание:"
    local ask_time="Введите время в формате ЧЧ:ММ (например, 03:00): "
    local msg_ok="✓ Расписание бэкапов успешно добавлено!"
    local back="Нажмите Enter для возврата..."
    
    if [ "$RLANG" == "EN" ]; then
        title="Configuring Auto-send Backups"
        ask_token="Enter Telegram Bot Token: "
        ask_chat="Enter Telegram Chat ID: "
        ask_topic="Enter Topic ID (leave empty if none): "
        ask_cron_title="Select backup frequency:"
        cron_opt1="Every hour (0 * * * *)"
        cron_opt2="Every day at midnight (0 0 * * *)"
        cron_opt3="Custom time (enter manually)"
        ask_schedule="Select schedule:"
        ask_time="Enter time in HH:MM format (e.g., 03:00): "
        msg_ok="✓ Backup schedule added successfully!"
        back="Press Enter to return..."
    fi

    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m     $title      \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""
    
    read -p "$ask_token" TG_TOKEN
    read -p "$ask_chat" TG_CHAT_ID
    read -p "$ask_topic" TG_TOPIC_ID
    
    # Создаем скрипт выполнения бэкапа
    mkdir -p /opt/remnatools
    cat <<'EOF' > /opt/remnatools/backup_worker.sh
#!/bin/bash
# ...existing code...
rm -rf $BACKUP_DIR
EOF

    chmod +x /opt/remnatools/backup_worker.sh
    
    echo "$ask_cron_title"
    local -a cron_options=("$cron_opt1" "$cron_opt2" "$cron_opt3")
    interactive_menu cron_options "$ask_schedule" 
    local choice=$?
    
    # Удаляем старые записи cron
    (crontab -l 2>/dev/null | grep -v "backup_worker.sh") | crontab - 2>/dev/null
    
    case $choice in
        0) (crontab -l 2>/dev/null; echo "0 * * * * /opt/remnatools/backup_worker.sh") | crontab - ;;
        1) (crontab -l 2>/dev/null; echo "0 0 * * * /opt/remnatools/backup_worker.sh") | crontab - ;;
        2) 
            read -p "$ask_time" B_TIME
            H=$(echo $B_TIME | cut -d: -f1)
            M=$(echo $B_TIME | cut -d: -f2)
            (crontab -l 2>/dev/null; echo "$M $H * * * /opt/remnatools/backup_worker.sh") | crontab -
            ;;
    esac
    
    save_config
    echo -e "\e[1;32m$msg_ok\e[0m"
    read -p "$back"
}

restore_backup() {
    clear
    local title="Восстановление системы из бэкапа"
    local msg_info="📌 Поместите файл бэкапа (.tar.gz) в /root/ перед этим"
    local ask_file="Введите имя файла (например, remna_backup_2026.tar.gz): "
    local msg_stopping="Останавливаем контейнеры..."
    local msg_unpacking="Распаковка резервной копии..."
    local msg_starting="Запуск восстановленных контейнеров..."
    local msg_ok="✓ Восстановление завершено!"
    local msg_err="✗ Файл не найден: /root/"
    local back="Нажмите Enter для возврата..."
    
    if [ "$RLANG" == "EN" ]; then
        title="Restoring System from Backup"
        msg_info="📌 Place the backup file (.tar.gz) in /root/ beforehand"
        ask_file="Enter filename (e.g., remna_backup_2026.tar.gz): "
        msg_stopping="Stopping containers..."
        msg_unpacking="Unpacking backup..."
        msg_starting="Starting restored containers..."
        msg_ok="✓ Restoration completed!"
        msg_err="✗ File not found: /root/"
        back="Press Enter to return..."
    fi

    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m       $title           \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""
    echo "$msg_info"
    echo ""
    read -p "$ask_file" B_FILE
    
    if [ -f "/root/$B_FILE" ]; then
        echo "$msg_stopping"
        cd /opt/remnawave 2>/dev/null && docker compose down 2>/dev/null
        cd /opt/remnanode 2>/dev/null && docker compose down 2>/dev/null
        
        echo "$msg_unpacking"
        tar -xzf /root/$B_FILE -C / 2>/dev/null
        
        echo "$msg_starting"
        cd /opt/remnawave 2>/dev/null && docker compose up -d 2>/dev/null
        cd /opt/remnanode 2>/dev/null && docker compose up -d 2>/dev/null
        
        echo -e "\e[1;32m$msg_ok\e[0m"
    else
        echo -e "\e[1;31m$msg_err$B_FILE\e[0m"
    fi
    
    read -p "$back"
}

manage_backups() {
    while true; do
        clear
        local title="Управление резервными копиями"
        local prompt="Выберите действие:"
        local opt1="1. Создать бэкап прямо сейчас"
        local opt2="2. Восстановиться из бэкапа"
        local opt3="3. Настройка автоотправки"
        local opt4="4. Назад в главное меню"
        
        if [ "$RLANG" == "EN" ]; then
            title="Backup Management"
            prompt="Select an action:"
            opt1="1. Create backup now"
            opt2="2. Restore from backup"
            opt3="3. Configure auto-send"
            opt4="4. Back to main menu"
        fi

        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m           $title          \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        
        local -a menu_items=("$opt1" "$opt2" "$opt3" "$opt4")
        interactive_menu menu_items "$(echo -e "\e[1;33m$prompt\e[0m")"
        local choice=$?
        
        case $choice in
            0) create_backup_now ;;
            1) restore_backup ;;
            2) configure_backup_auto ;;
            3) break ;;
            *) break ;;
        esac
    done
}

run_benchmarks() {
    clear
    # Цвета для оформления
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local NC='\033[0m' # Без цвета

    local title="Сборник тестов и бенчмарков для Linux-серверов"
    local opt_bbr="Включить оптимизацию сети (BBR)"
    local opt_ip_check="Проверить чистоту IP (IP.Check.Place)"
    local opt_ip_geo="Проверить геолокацию IP (IP Region)"
    local opt_yabs="Запустить YABS (CPU, Disk, IPv4 Network)"
    local opt_bench="Запустить Bench.sh (System info & Global Speed)"
    local opt_ru_speed="Тест скорости до провайдеров в РФ"
    local opt_speedtest="Установить и запустить Ookla Speedtest CLI"
    local opt_exit="Выход"
    local prompt="Выберите нужное действие (введите номер): "
    local msg_bbr="Включение BBR..."
    local msg_bbr_err="Ошибка: Для изменения параметров sysctl нужны права root (sudo)."
    local msg_bbr_ok="Готово! BBR активирован."
    local msg_ip_check="Проверка блокировок IP..."
    local msg_ip_geo="Проверка гео-теста (стриминговые платформы)..."
    local msg_yabs="Запуск YABS (только IPv4)..."
    local msg_bench="Запуск Bench.sh..."
    local msg_ru_speed="Проверка скорости до РФ..."
    local msg_speedtest="Скачивание и запуск официального Speedtest CLI..."
    local msg_speedtest_arch="Предупреждение: Скрипт качает версию для x86_64. Ваша архитектура: "
    local msg_speedtest_err="Не удалось скачать Speedtest CLI."
    local msg_exit="Возврат в главное меню..."
    local msg_invalid="Неверный выбор. Попробуйте еще раз."

    if [ "$RLANG" == "EN" ]; then
        title="Linux Server Tests & Benchmarks Collection"
        opt_bbr="Enable network optimization (BBR)"
        opt_ip_check="Check IP purity (IP.Check.Place)"
        opt_ip_geo="Check IP geolocation (IP Region)"
        opt_yabs="Run YABS (CPU, Disk, IPv4 Network)"
        opt_bench="Run Bench.sh (System info & Global Speed)"
        opt_ru_speed="Speed test to RU providers"
        opt_speedtest="Install & Run Ookla Speedtest CLI"
        opt_exit="Exit"
        prompt="Select an action (enter number): "
        msg_bbr="Enabling BBR..."
        msg_bbr_err="Error: Root privileges (sudo) are required to change sysctl parameters."
        msg_bbr_ok="Done! BBR is activated."
        msg_ip_check="Checking IP blocks..."
        msg_ip_geo="Checking Geo-test (streaming platforms)..."
        msg_yabs="Running YABS (IPv4 only)..."
        msg_bench="Running Bench.sh..."
        msg_ru_speed="Checking speed to RU..."
        msg_speedtest="Downloading and running official Speedtest CLI..."
        msg_speedtest_arch="Warning: Script downloads x86_64 version. Your architecture: "
        msg_speedtest_err="Failed to download Speedtest CLI."
        msg_exit="Returning to main menu..."
        msg_invalid="Invalid choice. Please try again."
    fi

    echo -e "${CYAN}=====================================================${NC}"
    echo -e "${YELLOW}  $title   ${NC}"
    echo -e "${CYAN}=====================================================${NC}"

    # Меню выбора
    local PS3="$prompt"
    local options=(
        "$opt_bbr"
        "$opt_ip_check"
        "$opt_ip_geo"
        "$opt_yabs"
        "$opt_bench"
        "$opt_ru_speed"
        "$opt_speedtest"
        "$opt_exit"
    )

    select opt in "${options[@]}"
    do
        case $opt in
            "$opt_bbr")
                echo -e "\n${YELLOW}>> $msg_bbr${NC}"
                if [ "$EUID" -ne 0 ]; then
                    echo -e "${RED}$msg_bbr_err${NC}\n"
                else
                    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
                    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
                    sysctl -p
                    echo -e "${GREEN}$msg_bbr_ok${NC}\n"
                fi
                ;;
            "$opt_ip_check")
                echo -e "\n${YELLOW}>> $msg_ip_check${NC}"
                bash <(curl -Ls IP.Check.Place | sed '/^\s*show_ad\s*$/d') -l en
                echo -e "\n"
                ;;
            "$opt_ip_geo")
                echo -e "\n${YELLOW}>> $msg_ip_geo${NC}"
                bash <(wget -qO- https://github.com/Davoyan/ipregion/raw/main/ipregion.sh)
                echo -e "\n"
                ;;
            "$opt_yabs")
                echo -e "\n${YELLOW}>> $msg_yabs${NC}"
                curl -sL yabs.sh | bash -s -- -4
                echo -e "\n"
                ;;
            "$opt_bench")
                echo -e "\n${YELLOW}>> $msg_bench${NC}"
                wget -qO- bench.sh | bash 
                echo -e "\n"
                ;;
            "$opt_ru_speed")
                echo -e "\n${YELLOW}>> $msg_ru_speed${NC}"
                wget -qO- bench.openode.xyz | bash
                echo -e "\n"
                ;;
            "$opt_speedtest")
                echo -e "\n${YELLOW}>> $msg_speedtest${NC}"
                local ARCH=$(uname -m)
                if [ "$ARCH" != "x86_64" ]; then
                    echo -e "${RED}$msg_speedtest_arch$ARCH${NC}"
                fi
                
                # Скачиваем во временную папку, чтобы не мусорить в текущей
                local TMP_DIR=$(mktemp -d)
                cd "$TMP_DIR" || exit
                
                if wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz; then
                    tar -xf ookla-speedtest-1.2.0-linux-x86_64.tgz
                    ./speedtest
                else
                    echo -e "${RED}$msg_speedtest_err${NC}"
                fi
                
                cd - > /dev/null || exit
                rm -rf "$TMP_DIR"
                echo -e "\n"
                ;;
            "$opt_exit")
                echo -e "${GREEN}$msg_exit${NC}"
                break
                ;;
            *) 
                echo -e "${RED}$msg_invalid ($REPLY)${NC}"
                ;;
        esac
    done
}

# --- ФУНКЦИЯ ИНТЕРАКТИВНОГО МЕНЮ ---
interactive_menu() {
    local -n options=$1
    local prompt="$2"
    local cursor=0
    
    while true; do
        clear
        # Заголовок теперь отображается здесь
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m                 $prompt               \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        
        for i in "${!options[@]}"; do
            if [ "$i" == "$cursor" ]; then
                echo -e " \e[1;36m➜ [\e[1;32m$(printf '%2d' $((i+1)))\e[0m]\e[0m ${options[$i]}"
            else
                echo -e "   [\e[1;33m$(printf '%2d' $((i+1)))\e[0m]  ${options[$i]}"
            fi
        done
        echo -e "\e[1;36m====================================================\e[0m"
        local help_msg="Управление: ↑↓ (стрелки) или w/s, Enter (выбрать)"
        if [ "$RLANG" == "EN" ]; then
            help_msg="Controls: ↑↓ (arrows) or w/s, Enter (select)"
        fi
        echo -e "$help_msg"
        echo ""
        
        read -rsn1 key
        
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
        fi

        case "$key" in
            ''|$'\n') 
                return $cursor 
                ;;
            "[A"|w) 
                ((cursor--))
                [ "$cursor" -lt 0 ] && cursor=$((${#options[@]} - 1))
                ;;
            "[B"|s) 
                ((cursor++))
                [ "$cursor" -ge ${#options[@]} ] && cursor=0
                ;;
        esac
    done
}

# --- УСКОРИТЕЛЬ НОДА ---

# Обновляет/скачивает директорию node-accelerator в постоянный кэш /opt/remnatools.
# Возвращает 0, если после этого в кэше есть рабочие скрипты.
refresh_node_accelerator_cache() {
    local own_dir
    own_dir="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

    # Запуск из git-клона (рядом с RWTools.sh лежит node-accelerator) - берём свежую копию оттуда
    if [ -d "$own_dir/node-accelerator/scripts" ]; then
        mkdir -p "$(dirname "$NODE_ACCELERATOR_PATH")"
        rm -rf "$NODE_ACCELERATOR_PATH"
        cp -r "$own_dir/node-accelerator" "$NODE_ACCELERATOR_PATH"
        return 0
    fi

    # Установлен только один файл /usr/local/bin/rwtools - качаем свежую версию с GitHub
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    if git clone --depth 1 --quiet "$NODE_ACCELERATOR_REPO" "$tmp_dir" 2>/dev/null \
        && [ -d "$tmp_dir/node-accelerator/scripts" ]; then
        mkdir -p "$(dirname "$NODE_ACCELERATOR_PATH")"
        rm -rf "$NODE_ACCELERATOR_PATH"
        cp -r "$tmp_dir/node-accelerator" "$NODE_ACCELERATOR_PATH"
        rm -rf "$tmp_dir"
        return 0
    fi
    rm -rf "$tmp_dir"

    # Не удалось обновить - используем то, что уже закэшировано ранее (если есть)
    [ -d "$NODE_ACCELERATOR_PATH/scripts" ]
}

run_node_accelerator() {
    refresh_node_accelerator_cache
    local na_path="$NODE_ACCELERATOR_PATH"

    # Проверяем, существует ли директория
    if [ ! -d "$na_path/scripts" ]; then
        if [ "$RLANG" == "RU" ]; then
            echo -e "\e[1;31m✗ Ошибка: Директория 'node-accelerator' не найдена и не удалось её загрузить (проверьте интернет-соединение).\e[0m"
        else
            echo -e "\e[1;31m✗ Error: Directory 'node-accelerator' not found and could not be downloaded (check your internet connection).\e[0m"
        fi
        read -p "Нажмите Enter для возврата..."
        return 1
    fi

    while true; do
        clear
        local title="Node.js Accelerator"
        local prompt="Выберите действие:"
        local opt1="Диагностика системы"
        local opt2="Оптимизировать (производительность + безопасность)"
        local opt3="Только безопасность"
        local opt4="Откатить изменения"
        local opt5="Создать отчет"
        local opt6="Назад в главное меню"
        
        if [ "$RLANG" == "EN" ]; then
            title="Node.js Accelerator"
            prompt="Select an action:"
            opt1="Diagnose system"
            opt2="Optimize (performance + security)"
            opt3="Security only"
            opt4="Rollback changes"
            opt5="Create report"
            opt6="Back to main menu"
        fi
        
        local -a menu_items=("$opt1" "$opt2" "$opt3" "$opt4" "$opt5" "$opt6")
        interactive_menu menu_items "$title"
        local choice=$?
        
        # Переходим в директорию со скриптами, чтобы они корректно работали
        cd "$na_path/scripts" || return
        
        case $choice in
            0) bash ./diagnose.sh ;;
            1) bash ./optimize.sh ;;
            2) bash ./protect.sh ;;
            3) bash ./rollback.sh ;;
            4) bash ./na-report.sh ;;
            5) cd - > /dev/null; break ;; # Возвращаемся из директории и выходим из цикла
            *) cd - > /dev/null; break ;; # Возвращаемся из директории и выходим из цикла
        esac
        
        # Возвращаемся обратно после выполнения скрипта
        cd - > /dev/null
        read -p "Нажмите Enter для продолжения..."
    done
}

# --- TRAFFIC GUARD (защита от сканеров портов) ---
# https://github.com/dotX12/traffic-guard
traffic_guard_status() {
    if command -v traffic-guard &>/dev/null; then
        echo -e "\e[1;32m✓ TrafficGuard установлен:\e[0m $(command -v traffic-guard)"
    else
        echo -e "\e[1;31m✗ TrafficGuard не установлен\e[0m"
        return
    fi

    if command -v ipset &>/dev/null && ipset list -n 2>/dev/null | grep -q '^SCANNERS-BLOCK-V4$'; then
        local v4_count v6_count
        v4_count=$(ipset list SCANNERS-BLOCK-V4 2>/dev/null | grep -cE '^[0-9]')
        v6_count=$(ipset list SCANNERS-BLOCK-V6 2>/dev/null | grep -cE '^[0-9a-fA-F]')
        echo -e "\e[1;32m✓ Защита активна:\e[0m заблокировано подсетей IPv4: $v4_count, IPv6: $v6_count"
    else
        echo -e "\e[1;33m✗ Защита не активна\e[0m (правила ipset не найдены)"
    fi

    if systemctl is-enabled antiscan-aggregate.timer &>/dev/null; then
        echo -e "\e[1;32m✓ Логирование включено\e[0m (antiscan-aggregate.timer)"
    fi
}

ensure_traffic_guard_installed() {
    if command -v traffic-guard &>/dev/null; then
        return 0
    fi
    echo "Устанавливаю TrafficGuard..."
    curl -fsSL "$TRAFFIC_GUARD_INSTALL_URL" | bash
    command -v traffic-guard &>/dev/null
}

# Устанавливает и включает ufw, предварительно разрешив текущий(е) SSH-порт(ы),
# чтобы не потерять доступ к серверу.
ensure_firewall_enabled() {
    if ! command -v ufw &>/dev/null; then
        echo "Устанавливаю ufw..."
        wait_for_apt_lock
        apt-get update -qq
        apt-get install -y ufw
    fi

    local -a ssh_ports=()
    while IFS= read -r port_line; do
        ssh_ports+=("$port_line")
    done < <(grep -E '^\s*Port\s+[0-9]+' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    [ ${#ssh_ports[@]} -eq 0 ] && ssh_ports=(22)

    local p
    for p in "${ssh_ports[@]}"; do
        ufw allow "${p}/tcp" comment "SSH (rwtools)" >/dev/null
    done

    if ufw status | grep -q "Status: active"; then
        echo -e "\e[1;32m✓ ufw уже активен\e[0m (SSH-порт(ы) разрешены: ${ssh_ports[*]})"
    else
        echo -e "Включаю ufw (SSH-порт(ы) заранее разрешены: \e[1;33m${ssh_ports[*]}\e[0m)..."
        ufw --force enable
    fi
}

# Спрашивает, включать ли логирование заблокированных подключений.
# Возвращает "1" через stdout, если да, иначе "0".
ask_traffic_guard_logging() {
    local title="Включить логирование заблокированных подключений?"
    local opt1="С логированием"
    local opt2="Без логирования"

    if [ "$RLANG" == "EN" ]; then
        title="Enable logging of blocked connections?"
        opt1="With logging"
        opt2="Without logging"
    fi

    local -a menu_items=("$opt1" "$opt2")
    interactive_menu menu_items "$title" >&2
    local choice=$?
    if [ "$choice" -eq 0 ]; then
        echo "1"
    else
        echo "0"
    fi
}

# Устанавливает (при необходимости), включает файрвол и применяет правила traffic-guard.
# Принимает: URL(ы) списков подсетей как отдельные аргументы.
apply_traffic_guard() {
    local -a list_urls=("$@")

    if ! ensure_traffic_guard_installed; then
        echo "Ошибка: не удалось установить traffic-guard (проверьте интернет-соединение)."
        return 1
    fi

    ensure_firewall_enabled

    local enable_logging
    enable_logging="$(ask_traffic_guard_logging)"

    local -a url_args=()
    local list_url
    for list_url in "${list_urls[@]}"; do
        url_args+=(-u "$list_url")
    done

    if [ "$enable_logging" == "1" ]; then
        traffic-guard full "${url_args[@]}" --enable-logging
    else
        traffic-guard full "${url_args[@]}"
    fi
}

run_traffic_guard() {
    while true; do
        clear
        local title="TrafficGuard - защита от сканеров портов"
        local opt1="Применить защиту (списки по умолчанию)"
        local opt2="Применить защиту (свой URL списка)"
        local opt3="Статус"
        local opt4="Удалить TrafficGuard"
        local opt5="Назад"

        if [ "$RLANG" == "EN" ]; then
            title="TrafficGuard - port scanner protection"
            opt1="Apply protection (default lists)"
            opt2="Apply protection (custom list URL)"
            opt3="Status"
            opt4="Remove TrafficGuard"
            opt5="Back"
        fi

        local -a menu_items=("$opt1" "$opt2" "$opt3" "$opt4" "$opt5")
        interactive_menu menu_items "$title"
        local choice=$?

        case $choice in
            0)
                apply_traffic_guard "${TRAFFIC_GUARD_DEFAULT_LISTS[@]}"
                read -p "Нажмите Enter для продолжения..."
                ;;
            1)
                local custom_url=""
                read -p "Введите URL списка подсетей: " custom_url
                if [ -n "$custom_url" ]; then
                    apply_traffic_guard "$custom_url"
                else
                    echo "URL не указан, отмена."
                fi
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                traffic_guard_status
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                if command -v traffic-guard &>/dev/null; then
                    traffic-guard uninstall --yes
                else
                    echo "TrafficGuard не установлен."
                fi
                read -p "Нажмите Enter для продолжения..."
                ;;
            4) break ;;
            *) break ;;
        esac
    done
}

# --- ПРОЧИЕ УТИЛИТЫ ---
run_other_utils() {
    while true; do
        clear
        local title="Прочие утилиты"
        local opt1="Включить/Отключить IPv6"
        local opt2="TrafficGuard (защита от сканеров портов)"
        local opt3="Назад в главное меню"

        if [ "$RLANG" == "EN" ]; then
            title="Other Utilities"
            opt1="Enable/Disable IPv6"
            opt2="TrafficGuard (port scanner protection)"
            opt3="Back to main menu"
        fi

        local -a menu_items=("$opt1" "$opt2" "$opt3")
        interactive_menu menu_items "$title"
        local choice=$?

        case $choice in
            0)
                mkdir -p "$(dirname "$IPV6_SCRIPT_PATH")"

                # Ищем скрипт рядом с самим RWTools.sh (например, при запуске из git-клона)
                # и всегда обновляем кэш, чтобы не залипнуть на старой версии
                local own_dir
                own_dir="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
                if [ -f "$own_dir/utils/ipv6_toggle.sh" ]; then
                    cp -f "$own_dir/utils/ipv6_toggle.sh" "$IPV6_SCRIPT_PATH"
                else
                    # Установлен только один файл /usr/local/bin/rwtools - пробуем перекачать свежую версию с GitHub
                    curl -fsSL "$IPV6_SCRIPT_URL" -o "${IPV6_SCRIPT_PATH}.new" 2>/dev/null \
                        && mv -f "${IPV6_SCRIPT_PATH}.new" "$IPV6_SCRIPT_PATH" \
                        || rm -f "${IPV6_SCRIPT_PATH}.new"
                fi

                if [ -f "$IPV6_SCRIPT_PATH" ]; then
                    chmod +x "$IPV6_SCRIPT_PATH"
                    bash "$IPV6_SCRIPT_PATH"
                else
                    echo "Ошибка: не удалось найти или загрузить ipv6_toggle.sh (проверьте интернет-соединение)."
                    sleep 2
                fi
                read -p "Нажмите Enter для продолжения..."
                ;;
            1) run_traffic_guard ;;
            2) break ;;
            *) break ;;
        esac
    done
}

# --- ОСНОВНОЕ МЕНЮ ---
main_menu() {
    while true; do
        clear
        local title="🚀 RemnaTools $VERSION"
        local opt1="Установить Панель"
        local opt2="Установить Ноду"
        local opt3="Управление бэкапами"
        local opt4="Тесты и Бенчмарки"
        local opt5="Ускоритель Node.js"
        local opt6="Прочие утилиты"
        local opt7="Обновить скрипт"
        local opt8="Сменить язык"
        local opt9="Удалить RemnaTools"
        local opt10="Выход"
        
        if [ "$RLANG" == "EN" ]; then
            title="🚀 RemnaTools $VERSION"
            opt1="Install Panel"
            opt2="Install Node"
            opt3="Backup Management"
            opt4="Tests & Benchmarks"
            opt5="Node.js Accelerator"
            opt6="Other Utilities"
            opt7="Update script"
            opt8="Change language"
            opt9="Uninstall RemnaTools"
            opt10="Exit"
        fi
        
        local -a menu_items=(
            "$opt1" "$opt2" "$opt3" "$opt4" 
            "$opt5" "$opt6" "$opt7" "$opt8" "$opt9" "$opt10"
        )
        interactive_menu menu_items "$title"
        local choice=$?
        
        case $choice in
            0) install_panel ;;
            1) install_node ;;
            2) manage_backups ;;
            3) run_benchmarks ;;
            4) run_node_accelerator ;;
            5) run_other_utils ;;
            6) update_script ;;
            7) change_language_menu ;;
            8) uninstall_script ;;
            9) exit 0 ;;
            *) exit 0 ;;
        esac
    done
}

# --- СТАРТ СКРИПТА ---
main_menu
