# 🤝 Contributing to RemnaTools

Thank you for your interest in contributing to RemnaTools! This document provides guidelines and instructions for developers.

## Code Structure

### Main Script: `RWTools.sh`

The main script is organized into logical sections:

#### Core Configuration
- `load_config()` - Loads settings from `/opt/remnatools/config.conf`
- `save_config()` - Persists settings to config file
- Platform definitions: `PLATFORM_APPS` associative array

#### User Interface
- `interactive_menu()` - Universal menu navigation with arrow keys
- `draw_platform_selection_menu()` - Per-platform app selection UI
- All menus use consistent navigation: ↑↓ arrows, Space to toggle, Enter to confirm

#### API Integration
- `get_existing_apps()` - Queries Panel API for existing app configurations
- Error handling with HTTP status codes
- Fallback endpoints for API compatibility

#### Infrastructure Installation
- `auto_install_panel()` - Caddy + PostgreSQL + Docker setup
- `auto_install_node()` - VPN node with BBR3, IPv6 settings

#### Backup Management
- `manage_backups()` - Main backup submenu
- `create_backup_now()` - Creates tar.gz and uploads to Telegram
- `configure_backup_auto()` - Sets up cron jobs for automatic backups
- `restore_backup()` - Extracts and restores from backup archive

#### System Operations
- `setup_subscription_page()` - Subscription configuration workflow
- Main menu loop and CLI flag handling

## Development Guidelines

### Bash Best Practices

1. **Use `local` for function variables:**
   ```bash
   my_function() {
       local var="value"
       local -a array=()
       local -A assoc=()
   }
   ```

2. **Proper quoting for string handling:**
   ```bash
   # Good
   echo "$var"
   if [[ "$var" == "value" ]]; then
   
   # Avoid
   echo $var
   if [ $var = value ]; then
   ```

3. **Error handling:**
   ```bash
   local response=$(curl -s ...)
   if [ $? -ne 0 ]; then
       echo "Error occurred"
       return 1
   fi
   ```

4. **Use `[[ ]]` for conditionals:**
   ```bash
   # Good
   if [[ "$name" =~ ^[a-z]+$ ]]; then
   
   # Less preferred
   if [ -n "$name" ]; then
   ```

### Adding New Features

1. **Add new menu option:**
   ```bash
   # In main menu loop
   "8")
       my_new_function
       ;;
   ```

2. **Create new function:**
   ```bash
   my_new_function() {
       local param1="$1"
       local param2="$2"
       
       echo "Processing..."
       # Implementation here
       
       return 0
   }
   ```

3. **Add configuration support:**
   ```bash
   # In load_config()
   MY_SETTING=${MY_SETTING:-"default_value"}
   
   # In save_config()
   echo "MY_SETTING=$MY_SETTING" >> "$CONFIG_FILE"
   ```

### UI Components

#### Arrow Key Navigation
The `interactive_menu()` function handles:
- `$'\x1b[A'` - Up arrow
- `$'\x1b[B'` - Down arrow
- `w` / `s` - Fallback keys
- `Enter` - Selection

Add to any menu:
```bash
interactive_menu "${menu_options[@]}"
selected=$?
```

#### Colored Output
```bash
echo -e "\033[32m✓ Success\033[0m"           # Green
echo -e "\033[33m⚠ Warning\033[0m"           # Yellow
echo -e "\033[31m✗ Error\033[0m"             # Red
echo -e "\033[36mℹ Info\033[0m"              # Cyan
```

## Modification Steps

### Before Making Changes

1. **Test Environment Setup:**
   ```bash
   # Clone the repository
   git clone https://github.com/remnawave/remnatools.git
   cd remnatools
   
   # Create a feature branch
   git checkout -b feature/your-feature-name
   ```

2. **Verify Script Syntax:**
   ```bash
   bash -n RWTools.sh
   ```

3. **Test on a staging server** before production deployment

### Making Changes

1. **Edit the script:**
   ```bash
   nano RWTools.sh
   ```

2. **Follow the coding style:**
   - 4-space indentation
   - Descriptive function names
   - Comments for complex logic
   - Russian comments for localized strings

3. **Add error handling:**
   ```bash
   if ! some_command; then
       echo "Error: Failed to execute command"
       return 1
   fi
   ```

### Testing Changes

1. **Syntax validation:**
   ```bash
   bash -n RWTools.sh
   ```

2. **Run in test mode:**
   ```bash
   sudo bash RWTools.sh --about
   ```

3. **Interactive testing:**
   ```bash
   sudo bash RWTools.sh
   # Navigate through your changes
   ```

4. **Test on multiple platforms** (if possible):
   - Ubuntu 18.04
   - Ubuntu 20.04
   - Ubuntu 22.04
   - Debian 10/11

### Submitting Changes

1. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: brief description of changes"
   ```

2. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request** with:
   - Clear description of changes
   - Why these changes are needed
   - Testing instructions
   - Any breaking changes

## Code Review Checklist

When reviewing code, ensure:

- [ ] Syntax is valid: `bash -n script.sh`
- [ ] Error handling is implemented
- [ ] Functions are properly documented
- [ ] Configuration is persisted correctly
- [ ] UI is consistent with existing menus
- [ ] Follows bash best practices
- [ ] No hardcoded paths (except system paths)
- [ ] Works with both Russian and English locales
- [ ] Tested on multiple Ubuntu versions

## Common Modifications

### Adding a New Platform

```bash
# In load_config()
PLATFORM_APPS["newplatform"]="App1 App2 App3"

# In draw_platform_selection_menu() - will auto-detect
# (function iterates through PLATFORM_APPS)
```

### Adding a New API Endpoint

```bash
get_new_data() {
    local url="$PANEL_URL/api/new/endpoint"
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" "$url" -w "\n%{http_code}")
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" != "200" ]; then
        echo "Error: HTTP $http_code"
        return 1
    fi
    
    echo "$body" | jq .
}
```

### Adding a New Cron Task

```bash
(crontab -l 2>/dev/null; echo "0 * * * * /opt/remnatools/task.sh") | crontab -
```

## Reporting Issues

When reporting bugs, include:

1. **OS and version:** `lsb_release -a`
2. **RemnaTools version:** Check inside script
3. **Error message:** Full output
4. **Steps to reproduce**
5. **Expected vs actual behavior**
6. **System state:** `docker ps`, `docker-compose ps`

## Security Considerations

When modifying the script:

- Never hardcode API tokens or passwords
- Validate all user inputs
- Use proper quoting to prevent injection
- Check HTTP status codes
- Implement rate limiting for API calls
- Store sensitive data with proper file permissions (600)

## Documentation

Update documentation when:

- Adding new features
- Changing command syntax
- Modifying configuration options
- Adding new platforms or applications

Files to update:
- `README.md` - User-facing documentation
- `README_RU.md` - Russian documentation
- `INSTALL.md` - Installation instructions
- Script comments - Code-level documentation

---

**Questions?** Open an issue or contact the Remnawave team.

Happy coding! 🚀
