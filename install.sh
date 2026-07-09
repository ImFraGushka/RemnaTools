#!/bin/bash

# Скрипт установки RemnaTools в систему

if [ "$EUID" -ne 0 ]; then
  echo "❌ Этот скрипт должен запускаться с правами root"
  echo "Используйте: sudo bash install.sh"
  exit 1
fi

echo -e "\e[1;36m====================================================\e[0m"
echo -e "\e[1;32m        Установка RemnaTools в систему...          \e[0m"
echo -e "\e[1;36m====================================================\e[0m"

# Найти путь к скрипту
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/RWTools.sh"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Ошибка: Файл RWTools.sh не найден в $SCRIPT_DIR"
    exit 1
fi

# Копируем скрипт в /usr/local/bin
echo "Копирование скрипта в /usr/local/bin/rwtools..."
cp "$SCRIPT_PATH" /usr/local/bin/rwtools
chmod +x /usr/local/bin/rwtools

# Копируем вспомогательные скрипты (например, utils/ipv6_toggle.sh) в постоянное расположение
if [ -d "$SCRIPT_DIR/utils" ]; then
    mkdir -p /opt/remnatools/utils
    cp -f "$SCRIPT_DIR"/utils/*.sh /opt/remnatools/utils/ 2>/dev/null || true
    chmod +x /opt/remnatools/utils/*.sh 2>/dev/null || true
fi

# Копируем node-accelerator в постоянное расположение
if [ -d "$SCRIPT_DIR/node-accelerator/scripts" ]; then
    rm -rf /opt/remnatools/node-accelerator
    cp -r "$SCRIPT_DIR/node-accelerator" /opt/remnatools/node-accelerator
    chmod +x /opt/remnatools/node-accelerator/scripts/*.sh 2>/dev/null || true
fi

# Создаем символическую ссылку (опционально)
ln -sf /usr/local/bin/rwtools /usr/bin/rwtools 2>/dev/null || true

echo -e "\e[1;32m    Добро пожаловать в установщик RemnaTools!     \e[0m"
echo -e "\e[1;36m====================================================\e[0m"

# Запускаем установку зависимостей и самой команды
bash RWTools.sh --install

echo -e "\e[1;32m✓ Установка завершена!\e[0m"
echo ""
echo "Теперь вы можете использовать команду:"
echo -e "  \e[1;33msudo rwtools\e[0m                - для запуска интерактивного меню"
echo -e "  \e[1;33msudo rwtools --about\e[0m        - для справки"
echo -e "  \e[1;33msudo rwtools --update\e[0m       - для обновления"
echo ""
echo "🎉 RemnaTools успешно установлена!"
