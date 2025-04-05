#!/bin/bash

VERSION="v1.1"
LOG_FILE="/tmp/chaotic_install.log"
LANGUAGE="en"

# Проверка флага -ru для выбора русского языка
if [[ "$1" == "-ru" ]]; then
    LANGUAGE="ru"
fi

# Функция для вывода сообщений на основе языка
function print_message {
    if [[ "$LANGUAGE" == "ru" ]]; then
        case $1 in
            "not_root") echo "[+] Переход на привилегии root..." ;;
            "adding_repo") echo "[+] Добавление репозитория Chaotic-AUR..." ;;
            "installing_yay") echo "[+] Установка yay..." ;;
            "complete") echo "[+] Установка завершена!" ;;
            "duplicate_entry") echo "[+] Запись уже существует в pacman.conf, пропуск..." ;;
        esac
    else
        case $1 in
            "not_root") echo "[+] Elevating to root privileges..." ;;
            "adding_repo") echo "[+] Adding Chaotic-AUR repository..." ;;
            "installing_yay") echo "[+] Installing yay..." ;;
            "complete") echo "[+] Installation complete!" ;;
            "duplicate_entry") echo "[+] Entry already exists in pacman.conf, skipping..." ;;
        esac
    fi
}

# Логирование вывода
exec > >(tee -a "$LOG_FILE") 2>&1

# Автоматическое повышение привилегий
if [ "$EUID" -ne 0 ]; then
    print_message "not_root"
    sudo "$0" "$@"
    exit
fi

# Добавление ключей и списка зеркал Chaotic-AUR
print_message "adding_repo"
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &>/dev/null
pacman-key --lsign-key 3056513887B78AEB &>/dev/null

# Установка ключей и списка зеркал Chaotic-AUR
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm &>/dev/null
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm &>/dev/null

# Проверка на дублирование записей в pacman.conf
if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
    echo '[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
else
    print_message "duplicate_entry"
fi

# Установка yay из Chaotic-AUR
print_message "installing_yay"
pacman -Sy --noconfirm yay &>/dev/null

# Синхронизация базы данных пакетов
yay -Syu --noconfirm &>/dev/null

print_message "complete"
