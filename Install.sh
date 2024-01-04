#!/bin/bash

# Author: Tritschla
# 2023-04

# Contributors: jfryman
# 2024-01 - Refactored create_shortcut function to be more generic

# This script does the following:
# 1. It is creating Resilio4SteamDeck (R4SD) environment
# 2. It is creating Resilio (rslsync) environment
# 3. It is initializing Pacman Arch Linux Keys
# 4. It is installing needed packages for Resilio
# 5. It is downloading the Resilio application
# 6. It is creating all needed entries for auto starting Resilio on System Boot, incl. GameMode
# 7. It is providing an Resilio4SteamRepair Script to reinstall needed packages, lost on SteamDeck OS updates
# 8. It is providing an Uninstaller for R4SD incl. Resilio

R4SD_DIR="$HOME/.R4SD"
REPO_URL="https://raw.githubusercontent.com/Tritschla/Resilio4SteamDeck/main"
RSLSYNC_DIR="$HOME/rslsync"

create_shortcut() {
    local name="$0"
    local comment="$1"
    local exec_command="$2"
    local icon="btsync-gui"
    local file_location="$3"

    # Remove existing file if it exists
    rm -rf "$file_location" 1>/dev/null

    # Create a new file with specified properties
    cat > "$file_location" << EOF
[Desktop Entry]
Name=$name
Comment=$comment
Exec=bash "$exec_command"
Icon=$icon
Terminal=false
Type=Application
StartupNotify=false
EOF

    # Set executable permissions for the file
    chmod +x "$file_location"
}

# Create the R4SD directory if it doesn't exist
mkdir -p "$R4SD_DIR" &>/dev/null

# Create the rslsync directory if it doesn't exist
mkdir -p "$RSLSYNC_DIR" &>/dev/null

# Prompt for sudo password
PASSWORD=$(zenity --password --title "Password required" --width=300 2> /dev/null)
if [[ -z $PASSWORD ]]; then
    zenity --error --text="Please enter your password." --width=300 2> /dev/null
    exit 1
fi

# Deactivate readonly filesystem
echo "$PASSWORD" | sudo -S steamos-readonly disable

# Initialize Arch Linux Keys
echo "$PASSWORD" | sudo -S pacman-key --init
echo "$PASSWORD" | sudo pacman -Sy archlinux-keyring --noconfirm
echo "$PASSWORD" | sudo pacman -Syy --noconfirm

# Install needed package
echo "$PASSWORD" | sudo -S pacman -Syyu --noconfirm lib32-libxcrypt-compat

# Download i386 rslsync package:
cd "$R4SD_DIR" || exit 1
wget https://download-cdn.resilio.com/stable/linux-i386/resilio-sync_i386.tar.gz
tar -xzf resilio-sync_i386.tar.gz -C "$RSLSYNC_DIR"

# Create Resilio rslsync_user.service
cat <<EOF > "$HOME/.config/systemd/user/rslsync_user.service"
[Unit]
Description=Resilio Sync per-user service
After=network.target

[Service]
Type=simple
ExecStart=/home/deck/rslsync/rslsync --nodaemon
Restart=on-abort

[Install]
WantedBy=default.target

EOF

# Enable and start rslsync_user service
systemctl --user enable rslsync_user
systemctl --user start rslsync_user

# Download RepairR4SD and Uninstall-R4SD scripts
SCRIPTS=("RepairR4SD.sh" "UninstallR4SD.sh")
for script in "${SCRIPTS[@]}"; do
    cd "$R4SD_DIR" || exit 1
    wget "$REPO_URL/$script"
    chmod +x "$R4SD_DIR/$script"
done

# Create desktop shortcuts
create_shortcut "Repair R4SD" \
    "This tool updates all necessary tools & packages to get Resilio Sync working after an update to SteamOS" \
    "$HOME/.R4SD/RepairR4SD.sh" \
    "$HOME/Desktop/RepairR4SD.desktop"
create_shortcut "Uninstall R4SD" \
    "This tool uninstalls the R4SD tools and packages" \
    "$HOME/.R4SD/UninstallR4SD.sh" \
    "$HOME/Desktop/UninstallR4SD.desktop"

# Create start menu shortcuts
create_shortcut "Repair R4SD" \
    "This tool updates all necessary tools & packages to get Resilio Sync working after an update to SteamOS" \
    "$HOME/.R4SD/RepairR4SD.sh" \
    "$HOME/.local/share/applications/RepairR4SD.desktop"

create_shortcut "Uninstall R4SD" \
    "This tool uninstalls the R4SD tools and packages" \
    "$HOME/.R4SD/UninstallR4SD.sh" \
    "$HOME/.local/share/applications/UninstallR4SD.desktop"

# Completion of the installation
zenity --info \
    --text="R4SD / Resilio has been successfully installed and can be accessed through a browser (e.g. Google Chrome) using the following link: http://localhost:8888" \
    --width=300 2> /dev/null
