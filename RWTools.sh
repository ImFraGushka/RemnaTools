#!/bin/bash

# Проверка на права root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root / Пожалуйста, запустите от имени root (sudo -i)"
  exit 1
fi

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

# --- ФУНКЦИЯ ДЛЯ ОТРИСОВКИ МЕНЮ С ГАЛОЧКАМИ ---
draw_multiselect_menu() {
    # Массив всех доступных приложений
    local apps=("Happ" "FlClashX" "v2raytun" "Karing" "Clash Mi" "INCY" "Rabbit Hole" "ShadowRocket" "Koala Clash" "Prizrak-Box" "Throne" "DeskBox")
    local cursor=0

    # Инициализируем массив выбранных приложений (все по умолчанию отмечены [*])
    for i in "${!apps[@]}"; do
        choices[$i]=1
    done

    # Функция рендеринга списка
    render_list() {
        clear
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;32m      Выбор приложений для Subscription-Page        \e[0m"
        echo -e "\e[1;36m====================================================\e[0m"
        echo -e "\e[1;33m Управление:\e[0m ↑/↓ — перемещение, Пробел — вкл/выкл, Enter — готово"
        echo -e "\e[1;36m----------------------------------------------------\e[0m"
        
        for i in "${!apps[@]}"; do
            local marker="[ ]"
            if [ "${choices[$i]}" == "1" ]; then
                marker="[\e[1;32m*\e[0m]"
            fi

            if [ "$i" == "$cursor" ]; then
                echo -e " \e[1;36m➔\e[0m $marker ${apps[$i]} \e[1;36m(текущий)\e[0m"
            else
                echo -e "   $marker ${apps[$i]}"
            fi
        done
        echo -e "\e[1;36m====================================================\e[0m"
    }

    # Цикл обработки нажатий клавиш
    while true; do
        render_list
        # Считываем коды клавиш (включая стрелки)
        read -rsn1 key
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 key
            if [[ "$key" == "[A" ]]; then # Стрелка вверх
                ((cursor--))
                [ $cursor -lt 0 ] && cursor=$((${#apps[@]} - 1))
            elif [[ "$key" == "[B" ]]; then # Стрелка вниз
                ((cursor++))
                [ $cursor -ge ${#apps[@]} ] && cursor=0
            fi
        elif [[ "$key" == "" ]]; then # Нажатие Enter
            break
        elif [[ "$key" == " " ]]; then # Нажатие Пробела
            if [ "${choices[$cursor]}" == "1" ]; then
                choices[$cursor]=0
            else
                choices[$cursor]=1
            fi
        fi
    done

    # Записываем результат глобально в ассоциативный массив APPS_SELECTION
    for i in "${!apps[@]}"; do
        if [ "${choices[$i]}" == "1" ]; then
            APPS_SELECTION["${apps[$i]}"]=true
        else
            APPS_SELECTION["${apps[$i]}"]=false
        fi
    done
}


# --- ОСНОВНАЯ ФУНКЦИЯ НАСТРОЙКИ СТРАНИЦЫ ПОДПИСОК ---
setup_subscription_page() {
    clear
    echo -e "\e[1;36m====================================================\e[0m"
    echo -e "\e[1;32m      Настройка Subscription-Page через API        \e[0m"
    echo -e "\e[1;36m====================================================\e[0m"
    
    # 1. Авторизация
    read -p "Введите URL вашей панели (например, https://panel.example.com): " PANEL_URL
    PANEL_URL="${PANEL_URL%/}"

    echo -e "\nВыберите способ авторизации:"
    echo "1) Использовать API Token (Рекомендуется)"
    echo "2) Использовать Логин и Пароль"
    read -p "Выбор (1-2): " AUTH_METHOD

    if [ "$AUTH_METHOD" == "1" ]; then
        read -p "Введите ваш API Token: " API_TOKEN
    else
        read -p "Введите Username (Email): " ADMIN_EMAIL
        read -s -p "Введите Пароль: " ADMIN_PASS
        echo -e "\n\nПолучаем API Токен..."
        AUTH_RESP=$(curl -s -X POST "$PANEL_URL/api/auth/login" \
            -H "Content-Type: application/json" \
            -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASS\"}")
        
        API_TOKEN=$(echo "$AUTH_RESP" | jq -r '.token // .accessToken // .data.token')
        if [ "$API_TOKEN" == "null" ] || [ -z "$API_TOKEN" ]; then
            echo -e "\e[1;31mОшибка авторизации! Проверьте логин и пароль.\e[0m"
            read -p "Нажмите Enter..."
            return
        fi
    fi

    # 2. Вызываем псевдографический чек-лист приложений
    declare -A APPS_SELECTION
    declare -a choices
    draw_multiselect_menu

    # 3. Конструктор JSON-блоков под дизайн с твоего скриншота image_98f7a0.png
    JSON_APPS_ARRAY="[]"

    build_app_json() {
        local name="$1"
        local os_list="$2"
        local install_btn_json="$3"
        local warn_text="$4"
        local manual_text="$5"
        local conn_text="$6"
        local deep_link_type="$7"

        jq -n \
            --arg name "$name" \
            --argjson platforms "$os_list" \
            --argjson buttons "$install_btn_json" \
            --arg warn "$warn_text" \
            --arg manual "$manual_text" \
            --arg conn "$conn_text" \
            --arg dl_type "$deep_link_type" \
            '{
                name: $name,
                platforms: $platforms,
                display: true,
                blocks: [
                    {
                        title: "Установка приложения",
                        icon: "download",
                        description: "Выберите архитектуру (предпочтительно установщик) и установите или распакуйте \($name).",
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

    echo "Генерируем конфигурацию..."

    # Блок Prizrak-Box (Строго по скрину image_98f7a0.png)
    if [ "${APPS_SELECTION["Prizrak-Box"]}" == "true" ]; then
        PZ_BTNS='[{"text":"Windows (Установщик)","url":"#","primary":false},{"text":"Windows на ARM (Установщик)","url":"#","primary":false}]'
        PZ_MANUAL="Если после нажатия на кнопку ничего не произошло, добавьте подписку вручную. Нажмите на этой страницу кнопку Получить ссылку в правом верхнем углу, скопируйте ссылку. В Prizrak-Box перейдите в раздел Профили, нажмите кнопку +, вставьте вашу скопированную ссылку и нажмите Подтвердить."
        PZ_CONN="Выберите добавленную подписку в разделе Профили. Выбрать страну сервера можно в разделе Прокси (🚀). Установите переключатель TUN в положение ВКЛ."
        
        PZ_JSON=$(build_app_json "Prizrak-Box" '["windows", "macos", "linux"]' "$PZ_BTNS" "Запустите программу от имени администратора." "$PZ_MANUAL" "$PZ_CONN" "MIHOMO_LINK")
        JSON_APPS_ARRAY=$(echo "$JSON_APPS_ARRAY" | jq ". + [$PZ_JSON]")
    fi

    # Блок Happ
    if [ "${APPS_SELECTION["Happ"]}" == "true" ]; then
        H_BTNS='[{"text":"Скачать APK (Universal)","url":"#","primary":false},{"text":"Google Play","url":"#","primary":false}]'
        H_MANUAL="Нажмите кнопку «Получить ссылку» вверху страницы, скопируйте ее. Откройте Happ, перейдите в Профили -> Нажмите «+» -> Вставьте ссылку."
        H_CONN="Выберите импортированный профиль. Во вкладке Прокси выберите локацию. Включите главный тумблер TUN."
        
        H_JSON=$(build_app_json "Happ" '["android", "ios", "windows", "macos", "linux", "tv"]' "$H_BTNS" "Разрешите установку из неизвестных источников в настройках Android." "$H_MANUAL" "$H_CONN" "HAPP_CRYPT4_LINK")
        JSON_APPS_ARRAY=$(echo "$JSON_APPS_ARRAY" | jq ". + [$H_JSON]")
    fi

    # Шаблонное заполнение для всех остальных выбранных приложений
    ALL_APPS=("Happ" "FlClashX" "v2raytun" "Karing" "Clash Mi" "INCY" "Rabbit Hole" "ShadowRocket" "Koala Clash" "Prizrak-Box" "Throne" "DeskBox")
    for app in "${ALL_APPS[@]}"; do
        if [ "$app" != "Prizrak-Box" ] && [ "$app" != "Happ" ] && [ "${APPS_SELECTION["$app"]}" == "true" ]; then
            PLATFORMS='["windows", "macos", "linux", "android", "ios"]'
            [ "$app" == "Rabbit Hole" ] && PLATFORMS='["ios", "macos"]'
            [ "$app" == "ShadowRocket" ] && PLATFORMS='["ios", "macos"]'
            
            GEN_BTNS="[{\"text\":\"Скачать клиент\",\"url\":\"#\",\"primary\":false}]"
            GEN_WARN="Рекомендуется запускать приложение от имени Администратора (или с root-правами для Linux/Android)."
            GEN_MANUAL="Скопируйте ссылку подписки (кнопка 'Получить ссылку' вверху экрана). В приложении перейдите в менеджер профилей, добавьте новый элемент и вставьте скопированный URL."
            GEN_CONN="Активируйте добавленную подписку. Переключите режим работы в положение TUN Mode или Системный прокси для маршрутизации трафика."
            
            GEN_JSON=$(build_app_json "$app" "$PLATFORMS" "$GEN_BTNS" "$GEN_WARN" "$GEN_MANUAL" "$GEN_CONN" "SING_BOX_LINK")
            JSON_APPS_ARRAY=$(echo "$JSON_APPS_ARRAY" | jq ". + [$GEN_JSON]")
        fi
    done

    # 4. Формируем тело запроса
    FINAL_PAYLOAD=$(jq -n --argjson apps "$JSON_APPS_ARRAY" '{
        metaTitle: "RemnaTools Subscription Page",
        metaDescription: "Быстрая настройка вашего защищенного соединения.",
        displayRawKeys: false,
        languages: ["ru", "en"],
        applications: $apps
    }')

    # 5. Публикация в панель
    echo "Отправка конфигурации в Remnawave API..."
    API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$PANEL_URL/api/system/subscription-page" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$FINAL_PAYLOAD")

    if [ "$API_STATUS" == "200" ] || [ "$API_STATUS" == "201" ]; then
        echo -e "\n\e[1;32m[Успех] Страница подписки идеально настроена! Изменения применились.\e[0m"
    else
        echo -e "\n\e[1;33mAPI вернул код $API_STATUS. Сохраняем локальный бэкап-файл...\e[0m"
        mkdir -p /opt/remnawave/subscription
        echo "$FINAL_PAYLOAD" | jq '.applications' > /opt/remnawave/subscription/app-config.json
        echo "Файл записан в: /opt/remnawave/subscription/app-config.json"
    fi

    read -p "Нажмите Enter для возврата в главное меню..."
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