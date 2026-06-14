#!/bin/bash

# Проверка на права root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root / Пожалуйста, запустите от имени root (sudo -i)"
  exit 1
fi

# Путь к локальной базе настроек скрипта
CONFIG_FILE="/opt/remnatools/config.conf"
UPDATE_URL="https://raw.githubusercontent.com/ImFraGushka/RemnaTools/main/RWTools.sh" # URL для обновления скрипта
mkdir -p /opt/remnatools

# --- ФУНКЦИЯ УДАЛЕНИЯ СКРИПТА ---
uninstall_script() {
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m           Удаление RemnaTools...                 \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""
    read -p "Вы уверены, что хотите полностью удалить RemnaTools? (y/n): " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[YyДд]$ ]]; then
        echo "Удаление скрипта из /usr/local/bin/rwtools..."
        sudo rm -f /usr/local/bin/rwtools
        
        echo "Удаление алиасов из .bashrc и .zshrc..."
        if [ -f ~/.bashrc ]; then
            sed -i 's/^alias rwtools=.*$//' ~/.bashrc 
            sed -i '/^$/N;/
$/N;/

/D' ~/.bashrc # Удаляем пустые строки, образовавшиеся после удаления алиаса
        fi
        if [ -f ~/.zshrc ]; then
            sed -i 's/^alias rwtools=.*$//' ~/.zshrc
            sed -i '/^$/N;/
$/N;/

/D' ~/.zshrc # Удаляем пустые строки, образовавшиеся после удаления алиаса
        fi
        
        echo -e "\e[1;32m✓ RemnaTools успешно удален!\e[0m"
    else
        echo "Удаление отменено."
    fi
    
    read -p "Нажмите Enter для возврата..."
}

# Флаг --delete
if [ "$1" == "--delete" ]; then
    uninstall_script
    exit 0
fi

# Флаг --delete
if [ "$1" == "--delete" ]; then
    uninstall_script
    exit 0
fi

# --- ФУНКЦИЯ УДАЛЕНИЯ СКРИПТА ---
uninstall_script() {
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m           Удаление RemnaTools...                 \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""
    read -p "Вы уверены, что хотите полностью удалить RemnaTools? (y/n): " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[YyДд]$ ]]; then
        echo "Удаление скрипта из /usr/local/bin/rwtools..."
        sudo rm -f /usr/local/bin/rwtools
        
        echo "Удаление алиасов из .bashrc и .zshrc..."
        if [ -f ~/.bashrc ]; then
            sed -i 's/^alias rwtools=.*$//' ~/.bashrc 
            sed -i '/^$/N;/
$/N;/

/D' ~/.bashrc # Удаляем пустые строки, образовавшиеся после удаления алиаса
        fi
        if [ -f ~/.zshrc ]; then
            sed -i 's/^alias rwtools=.*$//' ~/.zshrc
            sed -i '/^$/N;/
$/N;/

/D' ~/.zshrc # Удаляем пустые строки, образовавшиеся после удаления алиаса
        fi
        
        echo -e "\e[1;32m✓ RemnaTools успешно удален!\e[0m"
    else
        echo "Удаление отменено."
    fi
    
    read -p "Нажмите Enter для возврата..."
}

# Флаг --delete
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Читаем только валидные переменные (без дефисов в именах), чтобы избежать ошибок Bash
        while IFS='=' read -r key value; do
            if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                export "$key"="${value%\"}"
                export "$key"="${value#\"}"
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
EOF
}

# Инициализируем конфиг при старте
load_config

# Флаг --about
if [ "$1" == "--about" ]; then
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m                  🚀 RemnaTools v1.0.1             \e[0m"
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
    echo -e ""
    echo -e "\e[1;36m====================================================\e[0m"
    exit 0
fi

# Флаг --update
if [ "$1" == "--update" ]; then
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m           Обновление RemnaTools...                 \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo "Загрузка последней версии с GitHub..."
    
    # Определяем путь к текущему исполняемому файлу
    SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")
    
    # Загружаем новую версию во временный файл
    TMP_FILE=$(mktemp)
    if curl -fsSL "$UPDATE_URL" -o "$TMP_FILE"; then
        # Проверяем, не пустой ли файл скачался
        if [ ! -s "$TMP_FILE" ]; then
            echo -e "\e[1;31m✗ Ошибка: Скачанный файл пуст.\e[0m"
            rm -f "$TMP_FILE"
            exit 1
        fi
        
        # Проверяем синтаксис скачанного файла перед заменой
        if ! bash -n "$TMP_FILE"; then
            echo -e "\e[1;31m✗ Ошибка: Скачанный файл содержит синтаксические ошибки.\e[0m"
            rm -f "$TMP_FILE"
            exit 1
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
            echo -e "\e[1;32m✓ Скрипт успешно обновлен!\e[0m"
            echo "  Перезапустите скрипт для применения изменений."
        else
            echo -e "\e[1;31m✗ Ошибка при копировании файла.\e[0m"
            sudo mv "$BACKUP_PATH" "$SCRIPT_PATH"
        fi
        rm -f "$TMP_FILE"
    else
        echo -e "\e[1;31m✗ Ошибка при загрузке: проверьте интернет-соединение.\e[0m"
        exit 1
    fi
    exit 0
fi

# Флаг --install (установка rwtools команды)
if [ "$1" == "--install" ]; then
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m    Установка команды rwtools в систему...        \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/RWTools.sh"
    
    # Копируем скрипт в /usr/local/bin с сокращенным именем
    sudo cp "$SCRIPT_PATH" /usr/local/bin/rwtools
    sudo chmod +x /usr/local/bin/rwtools
    
    # Создаем алиас в bashrc и zshrc для быстрого доступа
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

# --- ФУНКЦИЯ УДАЛЕНИЯ СКРИПТА ---
uninstall_script() {
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m           Удаление RemnaTools...                 \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""
    read -p "Вы уверены, что хотите полностью удалить RemnaTools? (y/n): " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[YyДд]$ ]]; then
        echo "Удаление скрипта из /usr/local/bin/rwtools..."
        sudo rm -f /usr/local/bin/rwtools
        
        echo "Удаление алиасов из .bashrc и .zshrc..."
        if [ -f ~/.bashrc ]; then
            sed -i 's/^alias rwtools=.*$//' ~/.bashrc 
            sed -i '/^$/N;/
$/N;/

/D' ~/.bashrc # Удаляем пустые строки, образовавшиеся после удаления алиаса
        fi
        if [ -f ~/.zshrc ]; then
            sed -i 's/^alias rwtools=.*$//' ~/.zshrc
            sed -i '/^$/N;/
$/N;/

/D' ~/.zshrc # Удаляем пустые строки, образовавшиеся после удаления алиаса
        fi
        
        echo -e "\e[1;32m✓ RemnaTools успешно удален!\e[0m"
    else
        echo "Удаление отменено."
    fi
    
    read -p "Нажмите Enter для возврата..."
}

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
    else
        MSG_DOMAIN="Enter FRONT_END_DOMAIN (e.g., panel.example.com): "
        MSG_SUB="Enter SUB_PUBLIC_DOMAIN (e.g., sub.example.com): "
    fi

    read -p "$MSG_DOMAIN" FRONT_END_DOMAIN
    read -p "$MSG_SUB" SUB_PUBLIC_DOMAIN

    sudo curl -fsSL https://get.docker.com | sh
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
    echo "=== Запуск установки Ноды ==="
    export LANG=en_US.UTF-8
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
        MSG[updating]="Обновление системы..."
        MSG[enabling_bbr]="Включение стандартного BBR..."
        MSG[installing_bbr3]="Установка BBR3..."
        MSG[disabling_ipv6]="Отключение IPv6..."
        MSG[installing_docker]="Проверка и установка Docker..."
        MSG[conf_node]="Настройка Remnawave Node..."
        MSG[success]="Установка успешно завершена!"
    else
        MSG[welcome]="=== Remnawave Node Installation ==="
        MSG[ask_node_port]="Enter internal node port [default: 2222]: "
        MSG[ask_secret]="Enter node Secret Key: "
        MSG[ask_bbr3]="Do you want to install BBR3? (y/n): "
        MSG[ask_ipv6]="Do you want to disable IPv6? (y/n): "
        MSG[ask_ss_enable]="Do you want to configure SelfSteal (Caddy)? (y/n): "
        MSG[ask_domain]="Enter domain for SelfSteal (e.g., node.example.com): "
        MSG[ask_ss_port]="Enter port for SelfSteal [default: 9443]: "
        MSG[updating]="Updating system packages..."
        MSG[enabling_bbr]="Enabling standard BBR..."
        MSG[installing_bbr3]="Installing BBR3..."
        MSG[disabling_ipv6]="Disabling IPv6..."
        MSG[installing_docker]="Checking and installing Docker..."
        MSG[conf_node]="Configuring Remnawave Node..."
        MSG[success]="Installation completed successfully!"
    fi

    read -p "${MSG[ask_node_port]}" NODE_PORT
    NODE_PORT=${NODE_PORT:-2222}
    read -p "${MSG[ask_secret]}" SECRET_KEY
    read -p "${MSG[ask_bbr3]}" WANT_BBR3
    read -p "${MSG[ask_ipv6]}" WANT_IPV6
    read -p "${MSG[ask_ss_enable]}" WANT_SELFSTEAL

    if [[ "$WANT_SELFSTEAL" =~ ^[YyДд]$ ]]; then
        read -p "${MSG[ask_domain]}" SELF_STEAL_DOMAIN
        read -p "${MSG[ask_ss_port]}" SELF_STEAL_PORT
        SELF_STEAL_PORT=${SELF_STEAL_PORT:-9443}
    fi

    apt update && apt upgrade -y
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p

    if [[ "$WANT_BBR3" =~ ^[YyДд]$ ]]; then
        bash <(curl -sSL https://raw.githubusercontent.com/ivan-nginx/bbr3/main/optimize_network.sh)
    fi
    if [[ "$WANT_IPV6" =~ ^[YyДд]$ ]]; then
        echo -e "net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
        sysctl -p
    fi

    if ! command -v docker &> /dev/null; then sudo curl -fsSL https://get.docker.com | sh; fi

    mkdir -p /opt/remnanode && cd /opt/remnanode
    cat <<EOF > docker-compose.yml
services:
  remnanode:
    container_name: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
    environment:
      - NODE_PORT=${NODE_PORT}
      - SECRET_KEY="${SECRET_KEY}"
EOF
    docker compose up -d
    echo "${MSG[success]}"
    read -p "Нажмите Enter для возврата..."
}

# --- БЛОК БЭКАПОВ ---

create_backup_now() {
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m            Создание резервной копии...            \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    
    if [ -z "$TG_TOKEN" ] || [ -z "$TG_CHAT_ID" ]; then
        echo -e "\e[1;31m✗ Ошибка: Telegram не настроен!\e[0m"
        echo "  Перейдите в Управление бэкапами → Настройка автоотправки"
        read -p "Нажмите Enter для возврата..."
        return 1
    fi
    
    BACKUP_NAME="remna_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    BACKUP_DIR="/tmp/remna_backups"
    
    mkdir -p $BACKUP_DIR
    echo "Архивирование данных..."
    tar -czf $BACKUP_DIR/$BACKUP_NAME -C / opt/remnawave opt/remnanode 2>/dev/null
    
    if [ -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
        echo "Размер: $(du -h $BACKUP_DIR/$BACKUP_NAME | cut -f1)"
        echo "Отправка в Telegram..."
        
        if [ -z "$TG_TOPIC_ID" ]; then
            curl -s -F chat_id="$TG_CHAT_ID" -F document=@"$BACKUP_DIR/$BACKUP_NAME" \
                https://api.telegram.org/bot$TG_TOKEN/sendDocument >/dev/null 2>&1
        else
            curl -s -F chat_id="$TG_CHAT_ID" -F message_thread_id="$TG_TOPIC_ID" \
                -F document=@"$BACKUP_DIR/$BACKUP_NAME" \
                https://api.telegram.org/bot$TG_TOKEN/sendDocument >/dev/null 2>&1
        fi
        
        rm -rf $BACKUP_DIR
        echo -e "\e[1;32m✓ Бэкап успешно создан и отправлен!\e[0m"
    else
        echo -e "\e[1;31m✗ Ошибка при создании архива!\e[0m"
    fi
    
    read -p "Нажмите Enter для возврата..."
}

configure_backup_auto() {
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m     Настройка автоматической отправки бэкапов      \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""
    
    read -p "Введите Telegram Bot Token: " TG_TOKEN
    read -p "Введите Telegram Chat ID: " TG_CHAT_ID
    read -p "Введите Topic ID (оставьте пустым если нет): " TG_TOPIC_ID
    
    # Создаем скрипт выполнения бэкапа
    mkdir -p /opt/remnatools
    cat <<'EOF' > /opt/remnatools/backup_worker.sh
#!/bin/bash
TOKEN="$TG_TOKEN"
CHAT_ID="$TG_CHAT_ID"
TOPIC_ID="$TG_TOPIC_ID"
BACKUP_NAME="remna_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
BACKUP_DIR="/tmp/remna_backups"

mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/$BACKUP_NAME -C / opt/remnawave opt/remnanode 2>/dev/null

if [ -z "$TOPIC_ID" ]; then
    curl -s -F chat_id="$CHAT_ID" -F document=@"$BACKUP_DIR/$BACKUP_NAME" https://api.telegram.org/bot$TOKEN/sendDocument >/dev/null 2>&1
else
    curl -s -F chat_id="$CHAT_ID" -F message_thread_id="$TOPIC_ID" -F document=@"$BACKUP_DIR/$BACKUP_NAME" https://api.telegram.org/bot$TOKEN/sendDocument >/dev/null 2>&1
fi

rm -rf $BACKUP_DIR
EOF

    chmod +x /opt/remnatools/backup_worker.sh
    
    echo "Выберите периодичность бэкапов:"
    local -a cron_options=("Раз в час (0 * * * *)" "Раз в день в полночь (0 0 * * *)" "Точечное время (введу вручную)")
    interactive_menu cron_options "Выберите расписание:" 
    local choice=$?
    
    # Удаляем старые записи cron
    (crontab -l 2>/dev/null | grep -v "backup_worker.sh") | crontab - 2>/dev/null
    
    case $choice in
        0) (crontab -l 2>/dev/null; echo "0 * * * * /opt/remnatools/backup_worker.sh") | crontab - ;;
        1) (crontab -l 2>/dev/null; echo "0 0 * * * /opt/remnatools/backup_worker.sh") | crontab - ;;
        2) 
            read -p "Введите время в формате ЧЧ:ММ (например, 03:00): " B_TIME
            H=$(echo $B_TIME | cut -d: -f1)
            M=$(echo $B_TIME | cut -d: -f2)
            (crontab -l 2>/dev/null; echo "$M $H * * * /opt/remnatools/backup_worker.sh") | crontab -
            ;;
    esac
    
    save_config
    echo -e "\e[1;32m✓ Расписание бэкапов успешно добавлено!\e[0m"
    read -p "Нажмите Enter для возврата..."
}

restore_backup() {
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m       Восстановление системы из бэкапа           \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""
    echo "📌 Поместите файл бэкапа (.tar.gz) в /root/ перед этим"
    echo ""
    read -p "Введите имя файла (например, remna_backup_2026.tar.gz): " B_FILE
    
    if [ -f "/root/$B_FILE" ]; then
        echo "Останавливаем контейнеры..."
        cd /opt/remnawave 2>/dev/null && docker compose down 2>/dev/null
        cd /opt/remnanode 2>/dev/null && docker compose down 2>/dev/null
        
        echo "Распаковка резервной копии..."
        tar -xzf /root/$B_FILE -C / 2>/dev/null
        
        echo "Запуск восстановленных контейнеров..."
        cd /opt/remnawave 2>/dev/null && docker compose up -d 2>/dev/null
        cd /opt/remnanode 2>/dev/null && docker compose up -d 2>/dev/null
        
        echo -e "\e[1;32m✓ Восстановление завершено!\e[0m"
    else
        echo -e "\e[1;31m✗ Файл не найден: /root/$B_FILE\e[0m"
    fi
    
    read -p "Нажмите Enter для возврата..."
}

manage_backups() {
    while true; do
        clear
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m           Управление резервными копиями          \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        
        local -a menu_items=("1. Создать бэкап прямо сейчас" "2. Восстановиться из бэкапа" "3. Настройка автоотправки" "4. Назад в главное меню")
        interactive_menu menu_items "$(echo -e '\e[1;33mВыберите действие:\e[0m')"
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

    echo -e "${CYAN}=====================================================${NC}"
    echo -e "${YELLOW}  Сборник тестов и бенчмарков для Linux-серверов   ${NC}"
    echo -e "${CYAN}=====================================================${NC}"

    # Меню выбора
    local PS3="Выберите нужное действие (введите номер): "
    local options=(
        "Включить оптимизацию сети (BBR)"
        "Проверить чистоту IP (IP.Check.Place)"
        "Проверить геолокацию IP (IP Region)"
        "Запустить YABS (CPU, Disk, IPv4 Network)"
        "Запустить Bench.sh (System info & Global Speed)"
        "Тест скорости до провайдеров в РФ"
        "Установить и запустить Ookla Speedtest CLI"
        "Выход"
    )

    select opt in "${options[@]}"
    do
        case $opt in
            "Включить оптимизацию сети (BBR)")
                echo -e "\n${YELLOW}>> Включение BBR...${NC}"
                if [ "$EUID" -ne 0 ]; then
                    echo -e "${RED}Ошибка: Для изменения параметров sysctl нужны права root (sudo).${NC}\n"
                else
                    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
                    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
                    sysctl -p
                    echo -e "${GREEN}Готово! BBR активирован.${NC}\n"
                fi
                ;;
            "Проверить чистоту IP (IP.Check.Place)")
                echo -e "\n${YELLOW}>> Проверка блокировок IP...${NC}"
                bash <(curl -Ls IP.Check.Place | sed '/^\s*show_ad\s*$/d') -l en
                echo -e "\n"
                ;;
            "Проверить геолокацию IP (IP Region)")
                echo -e "\n${YELLOW}>> Проверка гео-теста (стриминговые платформы)...${NC}"
                bash <(wget -qO- https://github.com/Davoyan/ipregion/raw/main/ipregion.sh)
                echo -e "\n"
                ;;
            "Запустить YABS (CPU, Disk, IPv4 Network)")
                echo -e "\n${YELLOW}>> Запуск YABS (только IPv4)...${NC}"
                curl -sL yabs.sh | bash -s -- -4
                echo -e "\n"
                ;;
            "Запустить Bench.sh (System info & Global Speed)")
                echo -e "\n${YELLOW}>> Запуск Bench.sh...${NC}"
                wget -qO- bench.sh | bash 
                echo -e "\n"
                ;;
            "Тест скорости до провайдеров в РФ")
                echo -e "\n${YELLOW}>> Проверка скорости до РФ...${NC}"
                wget -qO- bench.openode.xyz | bash
                echo -e "\n"
                ;;
            "Установить и запустить Ookla Speedtest CLI")
                echo -e "\n${YELLOW}>> Скачивание и запуск официального Speedtest CLI...${NC}"
                local ARCH=$(uname -m)
                if [ "$ARCH" != "x86_64" ]; then
                    echo -e "${RED}Предупреждение: Скрипт качает версию для x86_64. Ваша архитектура: $ARCH${NC}"
                fi
                
                # Скачиваем во временную папку, чтобы не мусорить в текущей
                local TMP_DIR=$(mktemp -d)
                cd "$TMP_DIR" || exit
                
                if wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz; then
                    tar -xf ookla-speedtest-1.2.0-linux-x86_64.tgz
                    ./speedtest
                else
                    echo -e "${RED}Не удалось скачать Speedtest CLI.${NC}"
                fi
                
                cd - > /dev/null || exit
                rm -rf "$TMP_DIR"
                echo -e "\n"
                ;;
            "Выход")
                echo -e "${GREEN}Возврат в главное меню...${NC}"
                break
                ;;
            *) 
                echo -e "${RED}Неверный выбор $REPLY. Попробуйте еще раз.${NC}"
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
        echo -e "$prompt"
        echo -e "\e[1;36m====================================================\e[0m"
        
        for i in "${!options[@]}"; do
            if [ "$i" == "$cursor" ]; then
                echo -e " \e[1;36m➜ [\e[1;32m$(printf '%2d' $((i+1)))\e[0m]\e[0m ${options[$i]}"
            else
                echo -e "   [\e[1;33m$(printf '%2d' $((i+1)))\e[0m]  ${options[$i]}"
            fi
        done
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "Управление: ↑↓ (стрелки) или w/s, Enter (выбрать)"
        echo ""
        
        read -rsn1 key
        
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
        fi

        case "$key" in
            '[A'|w|W)
                ((cursor--))
                [ $cursor -lt 0 ] && cursor=$((${#options[@]} - 1))
                ;;
            '[B'|s|S)
                ((cursor++))
                [ $cursor -ge ${#options[@]} ] && cursor=0
                ;;
            "")
                return $cursor
                ;;
        esac
    done
}

# --- ГЛАВНОЕ МЕНЮ ИНСТРУМЕНТА ---
main_menu() {
    while true; do
        clear
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m          🚀 RemnaTools v1.0.1 (CLI)              \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        
        local -a menu_options=(
            "🔧 Автоустановка Панели (Caddy + DB + Docker)" 
            "🖥️  Автоустановка Remna Node" 
            "💾 Управление резервными копиями" 
            "📊 Тесты и бенчмарки" 
            "⬆️  Обновить скрипт" 
            "🗑️  Удалить RemnaTools" 
            "ℹ️  О нас" 
            "❌ Выход"
        )
        
        interactive_menu menu_options "$(echo -e '\e[1;33mВыберите действие:\e[0m')"
        local choice=$?
        
        case $choice in
            0) install_panel ;;
            1) install_node ;;
            2) manage_backups ;;
            3) run_benchmarks ;;
            4) "$0" --update; read -p "Нажмите Enter для возврата..." ;;
            5) uninstall_script ;;
            6) "$0" --about; read -p "Нажмите Enter для возврата..." ;;
            7) 
                clear
                echo -e "\e[1;32mСпасибо за использование RemnaTools! 👋\e[0m"
                exit 0
                ;;
            *) echo "Неверный выбор." && sleep 1 ;;
        esac
    done
}

# Запуск главного меню
main_menu