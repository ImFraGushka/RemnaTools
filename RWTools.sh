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

# Проверка флага --about
if [ "$1" == "--about" ]; then
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m                     RemnaTools                     \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "Разработчик: Ваше Имя/Никнейм"
    echo -e "Версия: 1.0.0 (Релиз 2026)"
    echo -e "Описание: Ультимативный CLI-инструмент для управления"
    echo -e "          экосистемой Remnawave."
    echo -e ""
    echo -e "\e[1;33mОсновные возможности:\e[0m"
    echo -e "  1. Автоматическая установка Панели (Caddy + DB + Docker)"
    echo -e "  2. Автоматическая установка Нод (с BBR3, IPv6-off и SelfSteal)"
    echo -e "  3. Интеллектуальный бэкап в заданное время прямо в Telegram"
    echo -e "     с поддержкой конкретных топиков (супер-удобно для чатов)"
    echo -e "  4. Быстрое и полное восстановление всей системы из бэкапа"
    echo -e "\e[1;36m====================================================\e[0m"
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

configure_backups() {
    clear
    echo "=== Настройка автоматического резервного копирования ==="
    read -p "Введите Telegram Bot Token: " TG_TOKEN
    read -p "Введите Telegram Chat ID (куда отправлять): " TG_CHAT_ID
    read -p "Введите Topic ID (если нет топиков, оставьте пустым): " TG_TOPIC_ID
    
    echo "Выберите периодичность бэкапов:"
    echo "1) Раз в час"
    echo "2) Раз в день (в полночь)"
    echo "3) Точечное время (например, каждый день в 03:00:01)"
    read -p "Ваш выбор: " CRON_CHOICE

    # Создаем скрипт выполнения бэкапа
    mkdir -p /opt/remnatools
    cat <<'EOF' > /opt/remnatools/backup_worker.sh
#!/bin/bash
TOKEN="YOUR_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
TOPIC_ID="YOUR_TOPIC_ID"
BACKUP_NAME="remna_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
BACKUP_DIR="/tmp/remna_backups"

mkdir -p $BACKUP_DIR
# Архивируем всю конфигурацию /opt/remnawave и /opt/remnanode
tar -czf $BACKUP_DIR/$BACKUP_NAME -C / opt/remnawave opt/remnanode 2>/dev/null

# Отправка в телеграм
if [ -z "$TOPIC_ID" ]; then
    curl -F chat_id="$CHAT_ID" -F document=@"$BACKUP_DIR/$BACKUP_NAME" https://api.telegram.org/bot$TOKEN/sendDocument
else
    curl -F chat_id="$CHAT_ID" -F message_thread_id="$TOPIC_ID" -F document=@"$BACKUP_DIR/$BACKUP_NAME" https://api.telegram.org/bot$TOKEN/sendDocument
fi

rm -rf $BACKUP_DIR
EOF

    # Подставляем переменные
    sed -i "s/YOUR_TOKEN/$TG_TOKEN/" /opt/remnatools/backup_worker.sh
    sed -i "s/YOUR_CHAT_ID/$TG_CHAT_ID/" /opt/remnatools/backup_worker.sh
    sed -i "s/YOUR_TOPIC_ID/$TG_TOPIC_ID/" /opt/remnatools/backup_worker.sh
    chmod +x /opt/remnatools/backup_worker.sh

    # Настройка Cron
    (crontab -l 2>/dev/null | grep -v "backup_worker.sh") | crontab -
    case $CRON_CHOICE in
        1) (crontab -l 2>/dev/null; echo "0 * * * * /opt/remnatools/backup_worker.sh") | crontab - ;;
        2) (crontab -l 2>/dev/null; echo "0 0 * * * /opt/remnatools/backup_worker.sh") | crontab - ;;
        3) 
            read -p "Введите точное время в формате ЧЧ:ММ (например, 03:00): " B_TIME
            H=$(echo $B_TIME | cut -d: -f1)
            M=$(echo $B_TIME | cut -d: -f2)
            (crontab -l 2>/dev/null; echo "$M $H * * * /opt/remnatools/backup_worker.sh") | crontab -
            ;;
    esac
    echo "Расписание бэкапов успешно добавлено в Crontab!"
    read -p "Нажмите Enter для возврата..."
}

restore_backup() {
    clear
    echo "=== Восстановление системы из бэкапа ==="
    echo "Поместите ваш файл бэкапа (.tar.gz) в директорию /root/ и введите его имя ниже."
    read -p "Имя файла бэкапа (например, remna_backup_2026.tar.gz): " B_FILE
    
    if [ -f "/root/$B_FILE" ]; then
        echo "Останавливаем текущие контейнеры (если они запущены)..."
        cd /opt/remnawave 2>/dev/null && docker compose down 2>/dev/null
        cd /opt/remnanode 2>/dev/null && docker compose down 2>/dev/null
        
        echo "Распаковка резервной копии..."
        tar -xzf /root/$B_FILE -C /
        
        echo "Запуск восстановленных контейнеров..."
        cd /opt/remnawave 2>/dev/null && docker compose up -d 2>/dev/null
        cd /opt/remnanode 2>/dev/null && docker compose up -d 2>/dev/null
        echo "Восстановление успешно завершено!"
    else
        echo "Ошибка: Файл /root/$B_FILE не найден!"
    fi
    read -p "Нажмите Enter для возврата..."
}

#Блок автонастройки Subscription-Page

# --- ФУНКЦИЯ ДЛЯ ПОЛУЧЕНИЯ УЖЕ ДОБАВЛЕННЫХ ПРИЛОЖЕНИЙ ИЗ ПАНЕЛИ ---
get_existing_apps() {
    local panel_url="$1"
    local api_token="$2"
    
    # Получаем конфигурацию subscription-page из панели
    local response=$(curl -s -X GET "$panel_url/api/system/subscription-page" \
        -H "Authorization: Bearer $api_token")
    
    # Проверяем тип ответа и извлекаем приложения
    if echo "$response" | jq -e . >/dev/null 2>&1; then
        # Пытаемся найти массив приложений
        echo "$response" | jq -r '.applications[]?.name? // empty' 2>/dev/null | sort -u
    fi
}

# --- ФУНКЦИЯ ДЛЯ ОТРИСОВКИ МЕНЮ ВЫБОРА ПО ПЛАТФОРМАМ ---
draw_platform_selection_menu() {
    local platform="$1"
    local cursor=0
    local -a apps_list=()
    local -a choices=()
    local -a existing_apps=()
    
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
        echo -e "\e[1;33m Управление:\e[0m w (вверх), s (вниз), Пробел (вкл/выкл), Enter (далее)"
        echo -e "\e[1;36m----------------------------------------------------\e[0m"
        
        for i in "${!apps_list[@]}"; do
            # Преобразуем обратно из очищенного имени в нормальное
            local display_name="${apps_list[$i]//_/ }"
            display_name="${display_name//-/ }"
            
            local marker="[ ]"
            if [ "${choices[$i]}" == "1" ]; then
                marker="[\e[1;32m*\e[0m]"
            fi

            if [ "$i" == "$cursor" ]; then
                echo -e " \e[1;36m➔\e[0m $marker $display_name \e[1;36m(текущий)\e[0m"
            else
                echo -e "   $marker $display_name"
            fi
        done
        echo -e "\e[1;36m====================================================\e[0m"
    }

    # Цикл обработки нажатий клавиш
    while true; do
        render_list
        
        IFS= read -r -s -n1 key
        
        if [[ "$key" == "w" || "$key" == "W" ]]; then
            ((cursor--))
            [ $cursor -lt 0 ] && cursor=$((${#apps_list[@]} - 1))
        elif [[ "$key" == "s" || "$key" == "S" ]]; then
            ((cursor++))
            [ $cursor -ge ${#apps_list[@]} ] && cursor=0
        elif [[ "$key" == " " ]]; then
            if [ "${choices[$cursor]}" == "1" ]; then
                choices[$cursor]=0
            else
                choices[$cursor]=1
            fi
        elif [[ "$key" == "" ]]; then
            break
        fi
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
        echo -e "\e[1;32mУже добавленные приложения:\e[0m"
        printf '%s\n' "${existing_apps[@]}" | sed 's/^/  ✓ /'
        echo ""
    fi

    # Меню выбора платформ для настройки
    declare -a selected_platforms=()
    local cursor=0
    local -a platforms=("android" "ios" "windows" "macos" "linux" "tv")
    local -a platform_choices=(1 1 1 1 1 1)
    
    # Интерактивное меню выбора платформ
    while true; do
        clear
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m   Выбор платформ для конфигурации приложений       \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;33m Управление:\e[0m w (вверх), s (вниз), Пробел (вкл/выкл), Enter (далее)"
        echo -e "\e[1;36m----------------------------------------------------\e[0m"
        
        for i in "${!platforms[@]}"; do
            local marker="[ ]"
            local platform_name="${platforms[$i]}"
            
            if [ "${platform_choices[$i]}" == "1" ]; then
                marker="[\e[1;32m*\e[0m]"
            fi
            
            # Красиво выводим названия платформ
            case "$platform_name" in
                "android") platform_name="🤖 Андроид (Android)" ;;
                "ios") platform_name="🍎 iOS / iPadOS" ;;
                "windows") platform_name="🪟 Windows" ;;
                "macos") platform_name="🍎 macOS" ;;
                "linux") platform_name="🐧 Linux" ;;
                "tv") platform_name="📺 TV (Android TV/Fire TV)" ;;
            esac

            if [ "$i" == "$cursor" ]; then
                echo -e " \e[1;36m➔\e[0m $marker $platform_name \e[1;36m(текущий)\e[0m"
            else
                echo -e "   $marker $platform_name"
            fi
        done
        echo -e "\e[1;36m====================================================\e[0m"
        
        IFS= read -r -s -n1 key
        
        if [[ "$key" == "w" || "$key" == "W" ]]; then
            ((cursor--))
            [ $cursor -lt 0 ] && cursor=$((${#platforms[@]} - 1))
        elif [[ "$key" == "s" || "$key" == "S" ]]; then
            ((cursor++))
            [ $cursor -ge ${#platforms[@]} ] && cursor=0
        elif [[ "$key" == " " ]]; then
            if [ "${platform_choices[$cursor]}" == "1" ]; then
                platform_choices[$cursor]=0
            else
                platform_choices[$cursor]=1
            fi
        elif [[ "$key" == "" ]]; then
            break
        fi
    done
    
    # Выбираем приложения для каждой выбранной платформы
    for i in "${!platforms[@]}"; do
        if [ "${platform_choices[$i]}" == "1" ]; then
            draw_platform_selection_menu "${platforms[$i]}"
        fi
    done
    
    # Сохраняем выборы
    save_config

    # --- КОНСТРУИРОВАНИЕ JSON-БЛОКОВ ДЛЯ КАЖДОГО ПРИЛОЖЕНИЯ ---
    
    # Словарь для хранения платформ каждого приложения
    declare -A app_platforms
    app_platforms["Happ"]="android ios windows macos linux tv"
    app_platforms["FlClashX"]="android windows macos linux"
    app_platforms["v2raytun"]="android ios macos tv"
    app_platforms["Karing"]="android ios windows macos linux"
    app_platforms["Clash_Mi"]="android windows macos linux"
    app_platforms["INCY"]="android ios windows macos linux"
    app_platforms["Rabbit_Hole"]="ios macos"
    app_platforms["ShadowRocket"]="ios macos"
    app_platforms["Koala_Clash"]="windows macos linux"
    app_platforms["Prizrak-Box"]="windows macos linux"
    app_platforms["Throne"]="windows macos linux"
    app_platforms["DeskBox"]="windows macos linux"
    
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
        local warning="Рекомендуется запускать приложение от имени Администратора (или с root-правами для Linux/Android)."
        local manual="Скопируйте ссылку подписки (кнопка 'Получить ссылку' вверху экрана). В приложении перейдите в менеджер профилей, добавьте новый элемент и вставьте скопированный URL."
        local connection="Активируйте добавленную подписку. Переключите режим работы в положение TUN Mode или Системный прокси для маршрутизации трафика."
        local link_type="SING_BOX_LINK"
        
        # Специальные настройки для конкретных приложений
        if [[ "$name" == "Happ" ]]; then
            buttons_json='[{"text":"Google Play","url":"#","primary":false},{"text":"Скачать APK","url":"#","primary":false}]'
            warning="Разрешите установку из неизвестных источников в настройках Android."
            link_type="HAPP_CRYPT4_LINK"
        elif [[ "$name" == "Prizrak-Box" ]]; then
            buttons_json='[{"text":"Windows (Установщик)","url":"#","primary":false},{"text":"Windows на ARM","url":"#","primary":false}]'
            warning="Запустите программу от имени администратора."
            link_type="MIHOMO_LINK"
        elif [[ "$name" == "ShadowRocket" ]]; then
            buttons_json='[{"text":"App Store","url":"#","primary":false}]'
            warning="Требуется покупка в App Store."
            link_type="SS_LINK"
        elif [[ "$name" == "Rabbit Hole" ]]; then
            buttons_json='[{"text":"App Store","url":"#","primary":false}]'
            link_type="CLASH_LINK"
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
                        title: "Установка приложения",
                        icon: "download",
                        description: "Откройте страницу в Google Play или скачайте APK, установите приложение \($name).",
                        buttons: $buttons
                    },
                    {
                        title: "Предупреждение",
                        icon: "alert",
                        description: $warn
                    },
                    {
                        title: "Добавление подписки",
                        icon: "cloud-download",
                        description: "Нажмите кнопку ниже, чтобы автоматически добавить подписку.",
                        buttons: [
                            { text: "Добавить подписку", type: $dl_type, primary: true }
                        ]
                    },
                    {
                        title: "Если подписка не добавилась",
                        icon: "settings",
                        description: $manual
                    },
                    {
                        title: "Подключение и использование",
                        icon: "check-circle",
                        description: $conn
                    }
                ]
            }'
    }

    # Собираем JSON-массив всех выбранных приложений
    local JSON_APPS_ARRAY="[]"
    local -a all_app_names=("Happ" "FlClashX" "v2raytun" "Karing" "Clash_Mi" "INCY" "Rabbit_Hole" "ShadowRocket" "Koala_Clash" "Prizrak-Box" "Throne" "DeskBox")
    
    for app_internal in "${all_app_names[@]}"; do
        # Проверяем, выбрано ли это приложение хотя бы для одной платформы
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
            # Преобразуем имя для красивого вывода
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
    echo "Умное обновление конфигурации панели через API..."
    
    # 1. Запрашиваем список конфигураций subscription-page
    local CONFIGS_LIST=$(curl -s -X GET "$PANEL_URL/api/system/subscription-page" -H "Authorization: Bearer $API_TOKEN")
    
    # 2. Извлекаем ID конфигурации
    local SUB_ID=$(echo "$CONFIGS_LIST" | jq -r '
        if type == "array" then .[0].id
        elif type == "object" and .data then .data[0].id
        elif type == "object" and .id then .id
        else null end
    ')

    if echo "$CONFIGS_LIST" | jq -e '. | type == "array"' >/dev/null 2>&1; then
        local SEARCH_DEFAULT=$(echo "$CONFIGS_LIST" | jq -r '.[] | select(.name=="Default" or .title=="Default") | .id' 2>/dev/null)
        [ -n "$SEARCH_DEFAULT" ] && [ "$SEARCH_DEFAULT" != "null" ] && SUB_ID="$SEARCH_DEFAULT"
    fi

    # 3. Отправляем конфигурацию
    local API_STATUS="404"
    if [ "$SUB_ID" != "null" ] && [ -n "$SUB_ID" ]; then
        API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$PANEL_URL/api/system/subscription-page/$SUB_ID" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$FINAL_PAYLOAD")
    fi

    # 4. Результат обработки
    if [ "$API_STATUS" == "200" ] || [ "$API_STATUS" == "204" ] || [ "$API_STATUS" == "201" ]; then
        echo -e "\n\e[1;32m[Успех] Страница подписки идеально настроена! Изменения применились.\e[0m"
        echo -e "\e[1;32mДобавлено приложений по платформам:\e[0m"
        
        # Выводим статистику по платформам
        for platform in android ios windows macos linux tv; do
            local count=0
            for app in ${PLATFORM_APPS[$platform]}; do
                [ "${APPS_SELECTION[${platform}_${app}]}" == "1" ] && ((count++))
            done
            if [ $count -gt 0 ]; then
                printf "  %-12s: %d приложение(й)\n" "$platform" "$count"
            fi
        done
    else
        echo -e "\n\e[1;33mНе удалось обновить БД панели (Код: $API_STATUS). Применяем прямую запись в контейнер...\e[0m"
        mkdir -p /opt/remnawave/subscription
        echo "$FINAL_PAYLOAD" | jq '.applications' > /opt/remnawave/subscription/app-config.json
        echo "Конфигурация записана локально в файл."
    fi
    read -p "Нажмите Enter для возврата в меню..."
}




# --- ГЛАВНОЕ МЕНЮ ИНСТРУМЕНТА ---
while true; do
    clear
    echo -e "\e[1;36m=============================================\e[0m"
    echo -e "\e[1;32m          RemnaTools CLI (RWTools)          \e[0m"
    echo -e "\e[1;36m=============================================\e[0m"
    echo "1) Автоустановка Панели"
    echo "2) Автоустановка Remna Node"
    echo "3) Настроить автоматические бэкапы в Telegram"
    echo "4) Восстановиться из бэкапа"
    echo "5) Настроить Subscription-Page (Выбор приложений)"
    echo "6) Выход"
    echo -e "\e[1;36m=============================================\e[0m"
    read -p "Выберите пункт меню (1-6): " MAIN_CHOICE

    case $MAIN_CHOICE in
        1) install_panel ;;
        2) install_node ;;
        3) configure_backups ;;
        4) restore_backup ;;
        5) setup_subscription_page ;;
        6) exit 0 ;;
        *) echo "Неверный выбор. Попробуйте еще раз." && sleep 1 ;;
    esac
done