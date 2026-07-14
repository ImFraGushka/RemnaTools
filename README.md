# 🚀 RemnaTools v1.4.0

choose your language: [Русский](https://github.com/ImFraGushka/RemnaTools/blob/main/README_RU.md)

The ultimate CLI tool for managing the Remnawave ecosystem on Linux/Ubuntu servers.

## 📋 Features

✓ **Auto Panel Installation** - Caddy + PostgreSQL + Docker in one click  
✓ **Auto Node Installation** - With BBR3, IPv6-off, SelfSteal support  
✓ **Backup Management** - Create, restore, and auto-upload to Telegram  
✓ **Auto Script Update** - Built-in update with backup  
✓ **TrafficGuard** - Blocks port scanner traffic via iptables/ipset  

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

### Node.js Accelerator Menu
```
1. Diagnose system
2. Optimize (performance + security)
3. Security only
4. Rollback changes
5. Create report
6. Back to main menu
```
## ⚡ Node.js Accelerator

Integrated set of scripts for optimization, diagnostics and protection of your server.
(Based on the original [node-accelerator](https://github.com/jestivald/node-accelerator/tree/main) repository).

Supports: Debian 11/12/13, Ubuntu 20.04–26.04.

### Key Features of the Accelerator:
- Diagnose system health and performance
- Optimize (performance + security)
- Security only
- Rollback changes
- Create report
- Back to main menu

## 🛡️ TrafficGuard

Blocks traffic from known port scanners at the firewall level using iptables and ipset.
(Based on the original [traffic-guard](https://github.com/dotX12/traffic-guard) project).

Available from the "Other Utilities" menu:
- Apply protection with default subnet blocklists
- Apply protection with a custom blocklist URL
- Status (installed / active rules / logging)
- Remove TrafficGuard

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

### Telegram Issues

- Verify bot token
- Check Chat ID is correct
- Bot must have access to the chat

## 🌐 Navigation

- **Arrow Keys**: ↑ Up / ↓ Down
- **WASD Keys**: W Up / S Down (alternative)
- **Space**: Toggle selection
- **Enter**: Confirm selection

## 📞 Contact with me

For questions and issues, contact: https://t.me/FraG_mmM
