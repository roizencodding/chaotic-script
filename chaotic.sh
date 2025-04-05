#!/bin/bash

LANG="en"
LOG_FILE="/tmp/chaotic_install.log"
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

exec_with_log() {
    echo "$(date): Running: $1" >> $LOG_FILE
    eval "$1" &>> $LOG_FILE
    return $?
}

if [ "$EUID" -ne 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

echo "" > $LOG_FILE

if [ "$LANG" = "ru" ]; then
    print_ru
else
    print_en
fi

exec_with_log "pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com"
exec_with_log "pacman-key --lsign-key 3056513887B78AEB"

exec_with_log "pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm"
exec_with_log "pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm"

if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    echo '[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
fi

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
