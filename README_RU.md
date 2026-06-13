# 🚀 RemnaTools v1.0.1

Ультимативный CLI-инструмент для управления экосистемой Remnawave на Linux/Ubuntu серверах.

## 📋 Возможности

✓ **Автоустановка Панели** - Caddy + PostgreSQL + Docker в один клик  
✓ **Автоустановка Ноды** - С поддержкой BBR3, IPv6-off, SelfSteal  
✓ **Управление бэкапами** - Создание и восстановление, автоотправка в Telegram  
✓ **Конфигурация Subscription-Page** - Выбор приложений для каждой платформы отдельно  
✓ **Обновление скрипта** - Встроенное обновление с резервной копией  

## 📱 Поддерживаемые платформы

- 🤖 **Android** (6 приложений)
- 🍎 **iOS** (6 приложений)
- 🪟 **Windows** (9 приложений)
- **macOS** (12 приложений)
- 🐧 **Linux** (9 приложений)
- 📺 **TV** (2 приложения)

## 📦 Поддерживаемые приложения

Happ, FlClashX, v2raytun, Karing, Clash Mi, INCY, Rabbit Hole, ShadowRocket, Koala Clash, Prizrak-Box, Throne, DeskBox

## 🔧 Установка

### Быстрая установка (рекомендуется)

```bash
git clone https://github.com/remnawave/remnatools.git
cd remnatools
sudo bash install.sh
```

Затем используйте команду:
```bash
sudo rwtools
```

### Ручная установка

```bash
sudo cp RWTools.sh /usr/local/bin/rwtools
sudo chmod +x /usr/local/bin/rwtools
```

## 💻 Использование

### Интерактивное меню
```bash
sudo rwtools
```

### Флаги командной строки
```bash
sudo rwtools --about      # Информация о скрипте
sudo rwtools --update     # Обновить скрипт
sudo rwtools --install    # Установить в систему
```

## 📖 Меню

```
1. Автоустановка Панели
2. Автоустановка Remna Node
3. Управление резервными копиями
   ├─ Создать бэкап сейчас
   ├─ Восстановиться из бэкапа
   └─ Настройка автоотправки
4. Настроить Subscription-Page
5. Обновить скрипт
6. О нас
7. Выход
```

## 🔐 Требования

- Ubuntu/Debian Linux
- Права root (`sudo`)
- Docker и Docker Compose
- curl, jq, tar
- Git (для обновления)

## ⚠️ Важно

- Скрипт требует прав root для установки
- Все данные хранятся в `/opt/remnatools/config.conf`
- Telegram токен и Chat ID сохраняются локально
- Резервные копии отправляются через Telegram API

## 🐛 Решение проблем

### API возвращает 404

Проверьте:
- URL панели (должен быть полный адрес с https://)
- API токен (должен быть активным)
- Убедитесь, что панель запущена и доступна

### Проблемы с Telegram

- Проверьте токен бота
- Убедитесь, что Chat ID правильный
- Бот должен иметь доступ к чату

## 📞 Поддержка

Для вопросов и проблем обратитесь к разработчику: https://t.me/FraG_mmM

---

**Версия:** 1.0.1  
**Лицензия:** MIT  
**Совместимость:** Linux/Ubuntu 18.04+
