#!/bin/bash

# Убедитесь, что скрипт запущен от имени root
if [ "$EUID" -ne 0 ]; then
    echo "Пожалуйста, запустите от имени root"
    exit
fi

# Добавление ключей и списка зеркал Chaotic-AUR
echo "Добавление репозитория Chaotic-AUR..."
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com &>/dev/null
pacman-key --lsign-key 3056513887B78AEB &>/dev/null

# Установка ключей и списка зеркал Chaotic-AUR
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm &>/dev/null
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm &>/dev/null

# Добавление Chaotic-AUR в pacman.conf
echo '[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf

# Установка yay из Chaotic-AUR
echo "Установка yay..."
pacman -Sy --noconfirm yay &>/dev/null

echo "Установка Chaotic-AUR и yay завершена!"