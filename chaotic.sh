#!/bin/bash

LANG="en"
LOG_FILE="$HOME/chaotic_install.log"
VERSION="1.2"

while getopts "ru" opt; do
  case $opt in
    ru) LANG="ru" ;;
  esac
done

print_en() {
    echo "[+] Chaotic-AUR Installer v${VERSION}"
    echo "[+] Adding Chaotic-AUR repository..."
    echo "[+] Installing yay..."
    echo "[+] Installation completed successfully!"
    echo "[+] Log saved to: ${LOG_FILE}"
}

print_ru() {
    echo "[+] Установщик Chaotic-AUR v${VERSION}"
    echo "[+] Добавление репозитория Chaotic-AUR..."
    echo "[+] Установка yay..."
    echo "[+] Установка успешно завершена!"
    echo "[+] Лог сохранен в: ${LOG_FILE}"
}

# Initialize log file safely
: > "$LOG_FILE"

# Ensure the log file is writable by creating it with appropriate permissions
sudo touch "$LOG_FILE" && sudo chmod 666 "$LOG_FILE"

# Ensure the log file is writable
if ! touch "$LOG_FILE" &>/dev/null; then
    echo "[!] Unable to write to $LOG_FILE. Falling back to /tmp/chaotic_install_$(date +%s).log."
    LOG_FILE="/tmp/chaotic_install_$(date +%s).log"
    : > "$LOG_FILE"
fi

# Error handling for exec_with_log
exec_with_log() {
    echo "$(date): Running: $1" >> "$LOG_FILE"
    eval "$1" &>> "$LOG_FILE"
    if [ $? -ne 0 ]; then
        echo "[!] Error occurred while executing: $1" >> "$LOG_FILE"
        exit 1
    fi
}

# Automatic privilege escalation
if [ "$EUID" -ne 0 ]; then
    echo "[+] Script is not running as root. Re-running with sudo..."
    sudo "$0" "$@"
    exit $?
fi

# Refactor redundant language checks
if [ "$LANG" = "ru" ]; then
    print_ru
else
    print_en
fi

# Check if the script has write permissions for the log file
if ! touch "$LOG_FILE" &>/dev/null; then
    echo "[!] Permission denied: Unable to write to $LOG_FILE. Please run the script with appropriate privileges." >&2
    exit 1
fi

# Add comments for clarity
# Adding Chaotic-AUR repository keys
exec_with_log "pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com"
exec_with_log "pacman-key --lsign-key 3056513887B78AEB"

# Installing Chaotic-AUR keyring and mirrorlist
exec_with_log "pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm"
exec_with_log "pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm"

# Adding Chaotic-AUR repository to pacman.conf
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    echo '[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
fi

# Synchronizing package database and installing yay
exec_with_log "pacman -Sy"
exec_with_log "pacman -S --noconfirm yay"

if [ "$LANG" = "ru" ]; then
    echo "[+] Синхронизация базы данных пакетов..."
    exec_with_log "yay -Syu"
    echo "[+] Готово! Теперь вы можете использовать yay для установки пакетов из AUR и Chaotic-AUR."
else
    echo "[+] Syncing package database..."
    exec_with_log "yay -Syu"
    echo "[+] Done! You can now use yay to install packages from AUR and Chaotic-AUR."
fi
