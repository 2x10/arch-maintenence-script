#!/usr/bin/env bash
# =============================================
#  Arch Linux Maintenance Script
#  Updates, cleans, and tidies the system
# =============================================

set -e  # Exit if any command fails
export LC_ALL=C

# ----- COLORS -----
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}=== Arch System Maintenance Started ===${RESET}"

# ----- UPDATE SYSTEM -----
echo -e "\n${YELLOW}Updating system packages (pacman)...${RESET}"
sudo pacman -Syu --noconfirm

# ----- UPDATE AUR PACKAGES -----
if command -v yay >/dev/null 2>&1; then
    echo -e "\n${YELLOW}Updating AUR packages (yay)...${RESET}"
    #yay -Syu --noconfirm --aur --devel
else
    echo -e "${YELLOW}yay not found — skipping AUR updates.${RESET}"
fi

# ----- REMOVE ORPHANED PACKAGES -----
echo -e "\n${YELLOW}Removing orphaned packages...${RESET}"
orphans=$(pacman -Qdtq || true)
if [[ -n "$orphans" ]]; then
    sudo pacman -Rns --noconfirm $orphans
else
    echo "No orphaned packages found."
fi

# ----- FLATPAK MAINTENANCE -----
if command -v flatpak >/dev/null 2>&1; then
    echo -e "\n${YELLOW}Updating Flatpak apps and runtimes...${RESET}"
    flatpak update -y

    echo -e "\n${YELLOW}Removing unused Flatpak runtimes...${RESET}"
    flatpak uninstall --unused -y

    echo -e "\n${YELLOW}Cleaning Flatpak cache...${RESET}"
    rm -rf ~/.var/app/*/cache/*
else
    echo -e "${YELLOW}Flatpak not found — skipping Flatpak maintenance.${RESET}"
fi

# ----- CLEAN PACKAGE CACHE -----
echo -e "\n${YELLOW}Cleaning pacman cache...${RESET}"
sudo paccache -r -k1   # keep only 1 version of each package

# ----- CLEAN TEMPORARY FILES -----
echo -e "\n${YELLOW}Cleaning /tmp and user cache...${RESET}"
sudo rm -rf /tmp/*
rm -rf ~/.cache/*

# ----- CLEAN PROGRAM CACHES -----
echo -e "\n${YELLOW}Cleaning app-specific caches...${RESET}"

# Steam
rm -rf ~/.steam/steam/appcache/* \
       ~/.steam/steam/config/htmlcache/* \
       ~/.steam/steam/htmlcache/* 2>/dev/null || true

# Firefox (clears cache, not bookmarks or logins)
find ~/.mozilla/firefox -type d -name "cache2" -exec rm -rf {} + 2>/dev/null || true

# Discord cache
rm -rf ~/.config/discord/Cache/* \
       ~/.config/discord/Code\ Cache/* \
       ~/.config/discord/GPUCache/* 2>/dev/null || true

# Waybar, nwg-panel, rofi caches
rm -rf ~/.cache/waybar/* ~/.cache/nwg-panel/* ~/.cache/rofi/* 2>/dev/null || true

# GNOME thumbnail cache
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true

# ----- JOURNAL & LOG CLEANUP -----
echo -e "\n${YELLOW}Cleaning system logs...${RESET}"
sudo journalctl --vacuum-time=7d   # keep only 7 days of logs

# ----- REBUILD FONT CACHE -----
echo -e "\n${YELLOW}Rebuilding font cache...${RESET}"
fc-cache -rv > /dev/null

# ----- CHECK FOR PACNEW/PACSAVE -----
echo -e "\n${YELLOW}Checking for leftover config files (pacnew/pacsave)...${RESET}"
sudo find /etc -type f \( -name "*.pacnew" -o -name "*.pacsave" \)

# ----- OPTIONAL HEALTH CHECK -----
echo -e "\n${YELLOW}Checking failed systemd units (if any)...${RESET}"
sudo systemctl --failed || true

# ----- DISK USAGE SUMMARY -----
echo -e "\n${YELLOW}Disk usage summary:${RESET}"
df -hT --exclude-type=tmpfs --exclude-type=devtmpfs

# ----- DONE -----
echo -e "\n${GREEN}=== System maintenance complete! ===${RESET}"
echo -e "✨ All updates and cleanup done."
