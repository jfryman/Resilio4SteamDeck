#!/bin/bash

# Author: Tritschla
# Date: 2023-04

# Prompt the user for uninstallation confirmation
if ! zenity --question --title="Uninstall R4SD?" --text="Are you sure you want to uninstall Resilio for Steam Deck?" --width=300 2> /dev/null; then
    exit 0
fi

# Stop and disable rslsync_user service
systemctl --user stop rslsync_user
systemctl --user disable rslsync_user

# Remove rslsync_user.service file
rm -f "$HOME/.config/systemd/user/rslsync_user.service"
systemctl --user daemon-reload

# Remove rslsync and R4SD folders
rm -rf "$HOME/rslsync"
rm -rf "$HOME/.R4SD"

# Remove desktop icons
rm -f "$HOME/Desktop/RepairR4SD.desktop"
rm -f "$HOME/Desktop/UninstallR4SD.desktop"

# Remove start menu entries
rm -f "$HOME/.local/share/applications/RepairR4SD.desktop"
rm -f "$HOME/.local/share/applications/UninstallR4SD.desktop"

# Notify the user about successful uninstallation
zenity --info \
    --title="Uninstall R4SD" \
    --text="Resilio for Steam Deck has been successfully uninstalled." \
    --width=300 2> /dev/null