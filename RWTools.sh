#!/bin/bash

# Проверка на права root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root / Пожалуйста, запустите от имени root (sudo -i)"
  exit 1
fi

# Путь к локальной базе настроек скрипта
CONFIG_FILE="/opt/remnatools/config.conf"
mkdir -p /opt/remnatools

# Функция загрузки сохраненных параметров
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    # Дефолтные значения, если настроек нет
    PANEL_URL=${PANEL_URL:-""}
    API_TOKEN=${API_TOKEN:-""}
    TG_TOKEN=${TG_TOKEN:-""}
    TG_CHAT_ID=${TG_CHAT_ID:-""}
    TG_TOPIC_ID=${TG_TOPIC_ID:-""}
    CRON_CHOICE=${CRON_CHOICE:-""}
    USER_TIME=${USER_TIME:-""}
    
    # Загрузка выбранных приложений по платформам (1 - включено, 0 - выключено)
    declare -g -A APPS_SELECTION
    
    # Инициализируем все платформы
    declare -g -A PLATFORM_APPS
    PLATFORM_APPS["android"]="Happ FlClashX v2raytun Karing Clash_Mi INCY"
    PLATFORM_APPS["ios"]="Happ Rabbit_Hole Karing v2raytun ShadowRocket INCY"
    PLATFORM_APPS["windows"]="Happ FlClashX Koala_Clash Karing Prizrak-Box Throne Clash_Mi INCY DeskBox"
    PLATFORM_APPS["macos"]="Happ FlClashX Rabbit_Hole Koala_Clash Karing Prizrak-Box Throne v2raytun ShadowRocket Clash_Mi INCY DeskBox"
    PLATFORM_APPS["linux"]="Happ FlClashX Koala_Clash Karing Prizrak-Box Throne Clash_Mi INCY DeskBox"
    PLATFORM_APPS["tv"]="v2raytun Happ"
    
    # Загружаем сохраненные выборы
    for platform in android ios windows macos linux tv; do
        for app in ${PLATFORM_APPS[$platform]}; do
            local var_name="SEL_${platform}_${app}"
            if [ -n "${!var_name}" ]; then
                APPS_SELECTION["${platform}_${app}"]=${!var_name}
            else
                APPS_SELECTION["${platform}_${app}"]=1
            fi
        done
    done
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
    
    # Сохраняем выборы по платформам
    for key in "${!APPS_SELECTION[@]}"; do
        echo "SEL_$key=\"${APPS_SELECTION[$key]}\"" >> "$CONFIG_FILE"
    done
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
    echo -e "   ✓ Конфигурация Subscription-Page с выбором приложений"
    echo -e ""
    echo -e "\e[1;33m📱 Поддерживаемые платформы:\e[0m"
    echo -e "   Android • iOS • Windows • macOS • Linux • TV"
    echo -e ""
    echo -e "\e[1;33m📦 Поддерживаемые приложения:\e[0m"
    echo -e "   Happ • FlClashX • v2raytun • Karing • Clash Mi • INCY"
    echo -e "   Rabbit Hole • ShadowRocket • Koala Clash • Prizrak-Box"
    echo -e "   Throne • DeskBox"
    echo -e ""
    echo -e "\e[1;36m====================================================\e[0m"
    exit 0
fi

# Флаг --update
if [ "$1" == "--update" ]; then
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m           Обновление RemnaTools...                 \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo "Загрузка последней версии со GitHub..."
    
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/RWTools.sh"
    BACKUP_PATH="$SCRIPT_PATH.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Создаем резервную копию
    cp "$SCRIPT_PATH" "$BACKUP_PATH"
    echo "✓ Резервная копия создана: $BACKUP_PATH"
    
    # Загружаем новую версию
    if curl -fsSL https://raw.githubusercontent.com/ImFraGushka/RemnaTools/main/RWTools.sh -o "$SCRIPT_PATH"; then
        chmod +x "$SCRIPT_PATH"
        echo -e "\e[1;32m✓ Скрипт успешно обновлен!\e[0m"
        echo "  Используйте 'rwtools' для запуска нового скрипта"
    else
        echo -e "\e[1;31m✗ Ошибка при загрузке: проверьте интернет-соединение\e[0m"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        echo "  Восстановлена предыдущая версия"
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
        echo "alias rwtools='sudo rwtools'" >> ~/.bashrc
    fi
    if [ -f ~/.zshrc ]; then
        echo "alias rwtools='sudo rwtools'" >> ~/.zshrc
    fi
    
    echo -e "\e[1;32m✓ Команда установлена!\e[0m"
    echo "  Используйте: rwtools"
    echo "  или: sudo rwtools"
    exit 0
fi

# --- ФУНКЦИИ УСТАНОВКИ ИЗ ВАШИХ ИСХОДНИКОВ ---

install_panel() {
    clear
    echo "=== Запуск установки Панели ==="
    # Интеграция вашего install.sh
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
    # Интеграция вашего install_remnawave.sh
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

# --- НОВЫЙ БЛОК: БЭКАПЫ И ВОССТАНОВЛЕНИЕ ---

# --- ФУНКЦИЯ БЫСТРОГО СОЗДАНИЯ БЭКАПА ---
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

# --- ФУНКЦИЯ КОНФИГУРАЦИИ АВТООТПРАВКИ ---
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

# --- ФУНКЦИЯ ВОССТАНОВЛЕНИЯ ИЗ БЭКАПА ---
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

# --- ПОДМЕНЮ УПРАВЛЕНИЯ БЭКАПАМИ ---
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

#Блок автонастройки Subscription-Page

# --- ФУНКЦИЯ ДЛЯ ПОЛУЧЕНИЯ УЖЕ ДОБАВЛЕННЫХ ПРИЛОЖЕНИЙ ИЗ ПАНЕЛИ ---
get_existing_apps() {
    local panel_url="$1"
    local api_token="$2"
    
    # Попытка 1: Получаем конфигурацию subscription-page
    local response=$(curl -s -X GET "$panel_url/api/system/subscription-page" \
        -H "Authorization: Bearer $api_token" \
        -w "\n%{http_code}")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    # Если 404 - пробуем альтернативный endpoint
    if [ "$http_code" == "404" ]; then
        response=$(curl -s -X GET "$panel_url/api/system/subscription-pages" \
            -H "Authorization: Bearer $api_token" \
            -w "\n%{http_code}")
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
    fi
    
    # Проверяем, валиден ли ответ
    if [ "$http_code" == "200" ] && echo "$body" | jq -e . >/dev/null 2>&1; then
        # Пытаемся найти приложения в разных структурах ответа
        echo "$body" | jq -r '
            if type == "array" then
                .[0].applications[]? | select(.name != null) | .name
            elif .data then
                .data[0].applications[]? | select(.name != null) | .name
            elif .applications then
                .applications[]? | select(.name != null) | .name
            else
                empty
            end
        ' 2>/dev/null | sort -u
    fi
}

# --- ФУНКЦИЯ ДЛЯ ИНТЕРАКТИВНОГО ВЫБОРА С СТРЕЛКАМИ ---
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
        
        # Обработка escape-последовательностей для стрелок
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
        fi

        case "$key" in
            '[A'|w|W) # Стрелка вверх или W
                ((cursor--))
                [ $cursor -lt 0 ] && cursor=$((${#options[@]} - 1))
                ;;
            '[B'|s|S) # Стрелка вниз или S
                ((cursor++))
                [ $cursor -ge ${#options[@]} ] && cursor=0
                ;;
            "") # Enter
                return $cursor
                ;;
        esac
    done
}

# --- ФУНКЦИЯ ДЛЯ ВЫБОРА ПРИЛОЖЕНИЙ ПО ПЛАТФОРМЕ (УЛУЧШЕННАЯ) ---
draw_platform_selection_menu() {
    local platform="$1"
    local cursor=0
    local -a apps_list=()
    local -a choices=()
    
    # Получаем список приложений для текущей платформы
    local app_string="${PLATFORM_APPS[$platform]}"
    IFS=' ' read -ra apps_list <<< "$app_string"
    
    # Инициализируем choices из сохраненных значений
    for i in "${!apps_list[@]}"; do
        local app_key="${platform}_${apps_list[$i]}"
        if [ -n "${APPS_SELECTION[$app_key]}" ]; then
            choices[$i]=${APPS_SELECTION[$app_key]}
        else
            choices[$i]=1
        fi
    done
    
    # Функция рендеринга списка
    render_list() {
        clear
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m  Выбор приложений для платформы: \e[1;33m$platform\e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;33m Управление:\e[0m ↑↓ (стрелки), Space (вкл/выкл), Enter (далее)"
        echo -e "\e[1;36m----------------------------------------------------\e[0m"
        
        for i in "${!apps_list[@]}"; do
            # Преобразуем обратно из очищенного имени в нормальное
            local display_name="${apps_list[$i]//_/ }"
            display_name="${display_name//-/ }"
            
            local marker="[ ]"
            if [ "${choices[$i]}" == "1" ]; then
                marker="[\e[1;32m✓\e[0m]"
            fi

            if [ "$i" == "$cursor" ]; then
                echo -e " \e[1;36m➜\e[0m $marker $display_name"
            else
                echo -e "   $marker $display_name"
            fi
        done
        echo -e "\e[1;36m====================================================\e[0m"
    }

    # Цикл обработки нажатий клавиш
    while true; do
        render_list
        
        read -rsn3 key
        
        case "$key" in
            $'\x1b[A'|w|W) # Стрелка вверх
                ((cursor--))
                [ $cursor -lt 0 ] && cursor=$((${#apps_list[@]} - 1))
                ;;
            $'\x1b[B'|s|S) # Стрелка вниз
                ((cursor++))
                [ $cursor -ge ${#apps_list[@]} ] && cursor=0
                ;;
            " ") # Space
                if [ "${choices[$cursor]}" == "1" ]; then
                    choices[$cursor]=0
                else
                    choices[$cursor]=1
                fi
                ;;
            "") # Enter
                break
                ;;
        esac
    done

    # Сохраняем измененные галочки
    for i in "${!apps_list[@]}"; do
        local app_key="${platform}_${apps_list[$i]}"
        APPS_SELECTION["$app_key"]=${choices[$i]}
    done
}


# --- ОСНОВНАЯ ФУНКЦИЯ НАСТРОЙКИ СТРАНИЦЫ ПОДПИСОК ---
setup_subscription_page() {
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m       Настройка Subscription-Page панели           \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo ""

    # Проверяем и запрашиваем URL панели
    if [ -n "$PANEL_URL" ]; then
        echo -e "Текущий URL панели: \e[1;32m$PANEL_URL\e[0m"
        read -p "Нажмите Enter для сохранения старого или введите новый URL: " INPUT_URL
        PANEL_URL=${INPUT_URL:-$PANEL_URL}
    else
        read -p "Введите URL панели (например, https://panel.domain.com): " PANEL_URL
    fi
    
    # Авто-фикс формата URL
    PANEL_URL="${PANEL_URL%/}"
    if [[ ! "$PANEL_URL" =~ ^https?:// ]]; then
        PANEL_URL="https://$PANEL_URL"
    fi

    # Проверяем и запрашиваем API токен
    if [ -n "$API_TOKEN" ]; then
        echo -e "API Токен: \e[1;32m[Уже сохранен в системе]\e[0m"
        read -p "Нажмите Enter для сохранения старого или введите новый токен: " INPUT_TOKEN
        API_TOKEN=${INPUT_TOKEN:-$API_TOKEN}
    else
        read -p "Введите ваш API Token панели: " API_TOKEN
    fi

    # Сохраняем параметры на диск
    save_config

    echo "Получаю информацию о текущих приложениях на панели..."
    local existing_apps=($(get_existing_apps "$PANEL_URL" "$API_TOKEN"))
    
    if [ ${#existing_apps[@]} -gt 0 ]; then
        echo -e "\e[1;32m✓ Найдены уже добавленные приложения:\e[0m"
        printf '%s\n' "${existing_apps[@]}" | sed 's/^/  ✔️  /'
        echo ""
    else
        echo -e "\e[1;33m⚠️  Приложения еще не добавлены\e[0m"
    fi
    
    sleep 1

    # Интерактивное меню для выбора каких платформ конфигурировать
    declare -a platform_names=("🤖 Андроид" "🍎 iOS" "🪟 Windows" "🍎 macOS" "🐧 Linux" "📺 TV")
    declare -a platform_codes=("android" "ios" "windows" "macos" "linux" "tv")
    declare -a selected_platforms=()
    
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m   Выберите платформы для конфигурации             \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo "Используйте Space для выбора/отвыбора, Enter для продолжения:"
    echo ""
    
    local cursor=0
    while true; do
        for i in "${!platform_names[@]}"; do
            if [ "$i" == "$cursor" ]; then
                echo -e -n " \e[1;36m➜\e[0m ${platform_names[$i]}"
            else
                echo -e -n "   ${platform_names[$i]}"
            fi
            
            # Проверяем, есть ли в PLATFORM_APPS
            if [ -n "${PLATFORM_APPS[${platform_codes[$i]}]}" ]; then
                echo ""
            fi
        done
        
        read -rsn3 key
        case "$key" in
            $'\x1b[A'|w|W) ((cursor--)); [ $cursor -lt 0 ] && cursor=$((${#platform_names[@]} - 1)) ;;
            $'\x1b[B'|s|S) ((cursor++)); [ $cursor -ge ${#platform_names[@]} ] && cursor=0 ;;
            "") break ;;
        esac
        clear
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m   Выберите платформы для конфигурации             \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        echo "Используйте Space для выбора/отвыбора, Enter для продолжения:"
        echo ""
    done
    
    # Выбираем приложения для каждой платформы
    for i in "${!platform_codes[@]}"; do
        draw_platform_selection_menu "${platform_codes[$i]}"
    done
    
    # Сохраняем выборы
    save_config
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m     Генерация и отправка конфигурации...          \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"

    # Собираем JSON-массив всех выбранных приложений
    local JSON_APPS_ARRAY="[]"
    local -a all_app_names=("Happ" "FlClashX" "v2raytun" "Karing" "Clash_Mi" "INCY" "Rabbit_Hole" "ShadowRocket" "Koala_Clash" "Prizrak-Box" "Throne" "DeskBox")
    
    # Функция для построения JSON-структуры приложения
    build_app_json() {
        local name="$1"
        local platforms_str="$2"
        
        # Преобразуем строку платформ в JSON-массив
        local platforms_json="["
        local first=1
        for p in $platforms_str; do
            if [ $first -eq 0 ]; then platforms_json+=","; fi
            platforms_json+="\"$p\""
            first=0
        done
        platforms_json+="]"
        
        # Специальные параметры для разных приложений
        local buttons_json='[{"text":"Скачать/Установить","url":"#","primary":false}]'
        local warning="Рекомендуется запускать приложение от имени Администратора."
        local manual="Скопируйте ссылку подписки и вставьте в приложение."
        local connection="Активируйте добавленную подписку в приложении."
        local link_type="SING_BOX_LINK"
        
        # Специальные настройки для конкретных приложений
        if [[ "$name" == "Happ" ]]; then
            buttons_json='[{"text":"Google Play","url":"#","primary":false},{"text":"APK","url":"#","primary":false}]'
            link_type="HAPP_CRYPT4_LINK"
        elif [[ "$name" == "Prizrak-Box" ]]; then
            buttons_json='[{"text":"Скачать (Windows)","url":"#","primary":false}]'
            link_type="MIHOMO_LINK"
        elif [[ "$name" == "v2raytun" ]]; then
            link_type="V2RAY_LINK"
        fi
        
        jq -n \
            --arg name "$name" \
            --argjson platforms "$platforms_json" \
            --argjson buttons "$buttons_json" \
            --arg warn "$warning" \
            --arg manual "$manual" \
            --arg conn "$connection" \
            --arg dl_type "$link_type" \
            '{
                name: $name,
                platforms: $platforms,
                display: true,
                blocks: [
                    {
                        title: "Установка",
                        icon: "download",
                        description: "Установите приложение \($name).",
                        buttons: $buttons
                    },
                    {
                        title: "Добавление подписки",
                        icon: "cloud-download",
                        description: "Нажмите кнопку для добавления подписки.",
                        buttons: [
                            { text: "Добавить подписку", type: $dl_type, primary: true }
                        ]
                    },
                    {
                        title: "Заметки",
                        icon: "info",
                        description: $warn
                    }
                ]
            }'
    }
    
    for app_internal in "${all_app_names[@]}"; do
        local is_selected=0
        local selected_platforms=""
        
        for platform in android ios windows macos linux tv; do
            local key="${platform}_${app_internal}"
            if [ "${APPS_SELECTION[$key]}" == "1" ]; then
                is_selected=1
                [ -z "$selected_platforms" ] && selected_platforms="$platform" || selected_platforms="$selected_platforms $platform"
            fi
        done
        
        if [ $is_selected -eq 1 ]; then
            local app_display="${app_internal//_/ }"
            local app_json=$(build_app_json "$app_display" "$selected_platforms")
            JSON_APPS_ARRAY=$(echo "$JSON_APPS_ARRAY" | jq ". + [$app_json]")
        fi
    done

    # Формируем финальный payload
    local FINAL_PAYLOAD=$(jq -n --argjson apps "$JSON_APPS_ARRAY" '{
        metaTitle: "RemnaTools Subscription Page",
        metaDescription: "Быстрая настройка вашего защищенного соединения.",
        displayRawKeys: false,
        languages: ["ru", "en"],
        applications: $apps
    }')

    # Публикуем конфигурацию на панель
    echo "Запрос на сервер панели..."
    
    local CONFIGS_LIST=$(curl -s -X GET "$PANEL_URL/api/system/subscription-page" -H "Authorization: Bearer $API_TOKEN" -w "\n%{http_code}")
    local http_code=$(echo "$CONFIGS_LIST" | tail -n1)
    local body=$(echo "$CONFIGS_LIST" | sed '$d')
    
    local SUB_ID=$(echo "$body" | jq -r '.id? // .[0].id? // empty' 2>/dev/null)

    local API_STATUS="404"
    if [ -n "$SUB_ID" ] && [ "$SUB_ID" != "null" ]; then
        API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$PANEL_URL/api/system/subscription-page/$SUB_ID" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$FINAL_PAYLOAD")
    fi

    # Результат обработки
    if [ "$API_STATUS" == "200" ] || [ "$API_STATUS" == "204" ] || [ "$API_STATUS" == "201" ]; then
        echo -e "\n\e[1;32m✓ Успех! Страница подписки обновлена.\e[0m"
        echo -e "\e[1;32mДобавлено приложений:\e[0m"
        
        for platform in android ios windows macos linux tv; do
            local count=0
            for app in ${PLATFORM_APPS[$platform]}; do
                [ "${APPS_SELECTION[${platform}_${app}]}" == "1" ] && ((count++))
            done
            if [ $count -gt 0 ]; then
                printf "  %-10s: %d\n" "$platform" "$count"
            fi
        done
    else
        echo -e "\n\e[1;31m✗ Ошибка API (код: $API_STATUS)\e[0m"
        echo "  Попробуйте проверить URL панели и API токен"
    fi
    read -p "Нажмите Enter для возврата..."
}

# --- ГЛАВНОЕ МЕНЮ ИНСТРУМЕНТА ---
main_menu() {
    while true; do
        clear
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m          🚀 RemnaTools v1.0.1 (CLI)              \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        
        local -a menu_options=(\
            "🔧 Автоустановка Панели (Caddy + DB + Docker)" \
            "🖥️  Автоустановка Remna Node" \
            "💾 Управление резервными копиями" \
            "📱 Настроить Subscription-Page" \
            "⬆️  Обновить скрипт" \
            "ℹ️  О нас" \
            "❌ Выход"
        )
        
        interactive_menu menu_options "$(echo -e '\e[1;33mВыберите действие:\e[0m')"
        local choice=$?
        
        case $choice in
            0) install_panel ;;
            1) install_node ;;
            2) manage_backups ;;
            3) setup_subscription_page ;;
            4) 
                "$0" --update
                # После обновления, скрипт будет перезапущен
                ;;
            5) "$0" --about ;;
            6) 
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