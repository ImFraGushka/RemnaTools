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

# Создаем символическую ссылку (опционально)
ln -sf /usr/local/bin/rwtools /usr/bin/rwtools 2>/dev/null || true

echo -e "\e[1;32m    Добро пожаловать в установщик RemnaTools!     \e[0m"
echo -e "\e[1;36m====================================================\e[0m"

# Запускаем установку зависимостей и самой команды
bash RWTools.sh --install

echo -e "\e[1;32m✓ Установка завершена!\e[0m"
echo "  Теперь вы можете использовать команду 'rwtools' из любого места."
echo "  Пример: sudo rwtools"
echo ""
