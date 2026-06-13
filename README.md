# 🚀 RemnaTools v1.0.1

choose your language: [Русский](https://github.com/ImFraGushka/RemnaTools/blob/main/README_RU.md)

The ultimate CLI tool for managing the Remnawave ecosystem on Linux/Ubuntu servers.

## 📋 Features

✓ **Auto Panel Installation** - Caddy + PostgreSQL + Docker in one click  
✓ **Auto Node Installation** - With BBR3, IPv6-off, SelfSteal support  
✓ **Backup Management** - Create, restore, and auto-upload to Telegram  
✓ **Auto Script Update** - Built-in update with backup  

## 📱 Supported Systems

- Ubuntu 18.04+
- Debian 10+

## 🔧 Installation

### Quick Install (recommended)

```bash
git clone https://github.com/ImFraGushka/RemnaTools.git
cd RemnaTools
sudo bash install.sh
```

Then use the command:
```bash
sudo rwtools
```

### Manual Installation

```bash
sudo cp RWTools.sh /usr/local/bin/rwtools
sudo chmod +x /usr/local/bin/rwtools
```

## 💻 Usage

### Interactive Menu
```bash
sudo rwtools
```

### Command Line Flags
```bash
sudo rwtools --about      # About script
sudo rwtools --update     # Update script
sudo rwtools --install    # Install to system
```

## 📖 Main Menu

```
1. Auto Install Panel
2. Auto Install Remna Node
3. Backup Management
   ├─ Create Backup Now
   ├─ Restore from Backup
   └─ Configure Auto Upload
4. Update Script
5. About
6. Exit
```

## 🔐 Requirements

- Ubuntu/Debian Linux
- Root privileges (`sudo`)
- Docker and Docker Compose
- curl, jq, tar
- Git (for updates)

## ⚠️ Important Notes

- Script requires root to install
- All data stored in `/opt/remnatools/config.conf`
- Telegram token and Chat ID stored locally
- Backups uploaded via Telegram API
- Arrow keys (↑↓) for navigation, Space to select/deselect, Enter to confirm

## 🐛 Troubleshooting

### API Returns 404

Check:
- Panel URL (should be complete with https://)
- API token (must be active)
- Ensure panel is running and accessible

### Telegram Issues

- Verify bot token
- Check Chat ID is correct
- Bot must have access to the chat

## 🌐 Navigation

- **Arrow Keys**: ↑ Up / ↓ Down
- **WASD Keys**: W Up / S Down (alternative)
- **Space**: Toggle selection
- **Enter**: Confirm selection

## 📞 Support

For questions and issues, contact: https://t.me/FraG_mmM

---

**Version:** 1.0.1  
**License:** MIT  
**Compatibility:** Linux/Ubuntu 18.04+
