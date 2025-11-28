#!/bin/bash
# =======================================================
# Debian → Archcraft Openbox Full Installer (Single-File)
# Author: Seyed Adrian Saberifar (Modified)
# Features: GUI progress bars, clickable EFI selection, single sudo password, error log
# =======================================================


# -----------------------------
# Installer home directory
INSTALLER_HOME="$HOME/.archcraft_installer"
mkdir -p "$INSTALLER_HOME"

# -----------------------------
# Logs
LOG_FILE="$INSTALLER_HOME/archcraft_install_errors.txt"
: > "$LOG_FILE"

# -----------------------------
# Function to log warnings/errors only
log_msg() {
    local msg="$1"
    if [[ "$msg" == *warning* ]] || [[ "$msg" == *error* ]] || [[ "$msg" == *failed* ]]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

# -----------------------------
# Progress bar with Zenity
progress_start() {
    exec 3> >(zenity --progress \
        --title="Archcraft Installer" \
        --text="$1" \
        --percentage=0 \
        --auto-close \
        --width=500)
}

progress_update() {
    local pct="$1"
    echo "$pct" >&3
}

progress_end() {
    exec 3>&-
}

# -----------------------------
# Request sudo once
sudo -v || { echo "This installer requires sudo access"; exit 1; }

# Keep sudo alive
( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done ) 2>/dev/null &

# -----------------------------
# Start installer progress
progress_start "Starting Archcraft Openbox Installer..."
progress_update 5

# -----------------------------
# Ensure core dependencies
PACKAGES=(sudo wget git curl unzip xz-utils tar build-essential cmake make meson ninja-build python3 python3-tk xprintidle zenity fastfetch)
for pkg in "${PACKAGES[@]}"; do
    dpkg -s "$pkg" &>/dev/null || {
        echo "Installing missing package: $pkg"
        if ! sudo apt-get install -y "$pkg" 2>&1 | tee -a "$LOG_FILE"; then
            log_msg "Error installing $pkg"
        fi
    }
done
progress_update 15
# -----------------------------
# EFI detection & selection via Zenity list
EFI_DEVICES=($(lsblk -o NAME,LABEL,FSTYPE | grep -i EFI | awk '{print "/dev/"$1}'))

if [ ${#EFI_DEVICES[@]} -eq 0 ]; then
    EFI_CHOICE=$(zenity --entry \
        --title="Limine EFI Installer" \
        --text="No EFI partitions auto-detected. Enter EFI partition manually:" \
        --entry-text "/dev/sda1")
else
    EFI_CHOICE=$(zenity --list \
        --title="Select EFI Partition" \
        --column="EFI Devices" "${EFI_DEVICES[@]}")
fi
progress_update 20

# -----------------------------
# Prepare Limine bootloader download
progress_start "Installing Limine EFI Bootloader..."
LIMINE_DIR="$INSTALLER_HOME/limine"
mkdir -p "$LIMINE_DIR"
LIMINE_ZIP="$LIMINE_DIR/limine.zip"
LIMINE_URL="https://github.com/limine-bootloader/limine/releases/download/4.16/limine-4.16.zip"

if ! wget -O "$LIMINE_ZIP" "$LIMINE_URL" 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error downloading Limine"
fi

if unzip "$LIMINE_ZIP" -d "$LIMINE_DIR" 2>&1 | tee -a "$LOG_FILE"; then
    cd "$LIMINE_DIR" || log_msg "Cannot cd to $LIMINE_DIR"
    sudo make install 2>&1 | tee -a "$LOG_FILE" || log_msg "Error installing Limine"
else
    log_msg "Limine unzip failed"
fi
progress_update 30

# -----------------------------
# Prepare Fira Code for Alacritty
FIRA_DIR="$INSTALLER_HOME/fonts/FiraCode"
mkdir -p "$FIRA_DIR"
FIRA_ZIP="$FIRA_DIR/FiraCode.zip"
FIRA_URL="https://github.com/tonsky/FiraCode/releases/download/6.6/Fira_Code_v6.6.zip"

progress_start "Downloading Fira Code font for Alacritty..."
if ! wget -O "$FIRA_ZIP" "$FIRA_URL" 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error downloading Fira Code"
fi

# Unzip and install Fira Code locally
if unzip -o "$FIRA_ZIP" -d "$FIRA_DIR" 2>&1 | tee -a "$LOG_FILE"; then
    mkdir -p "$HOME/.local/share/fonts"
    cp -v "$FIRA_DIR/ttf/"*.ttf "$HOME/.local/share/fonts/" 2>&1 | tee -a "$LOG_FILE" || log_msg "Error copying Fira Code fonts"
    fc-cache -fv 2>&1 | tee -a "$LOG_FILE" || log_msg "Error updating font cache"
else
    log_msg "Fira Code unzip failed"
fi
progress_update 40

# -----------------------------
# Alacritty config pointing to Fira Code
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"

cat > "$ALACRITTY_CONFIG_DIR/alacritty.yml" <<EOF
font:
  normal:
    family: "Fira Code"
    style: "Regular"
EOF
progress_update 45
# -----------------------------
# Core DE/WM packages (excluding Alacritty, already handled)
CORE_PKGS=(xorg openbox obconf plank xfce4 xfce4-goodies rofi nitrogen feh kitty pcmanfm)
progress_start "Installing core packages..."
for pkg in "${CORE_PKGS[@]}"; do
    echo "Installing $pkg..."
    if ! sudo apt-get install -y "$pkg" 2>&1 | tee -a "$LOG_FILE"; then
        log_msg "Error installing $pkg"
    fi
done
progress_update 55

# -----------------------------
# Create user config directories under hidden installer folder
USER_DIRS=(
    "$HOME/.archcraft_installer/.config/autostart"
    "$HOME/.archcraft_installer/.local/share/fonts"
    "$HOME/.archcraft_installer/.config/alacritty"
)

for dir in "${USER_DIRS[@]}"; do
    mkdir -p "$dir" 2>/dev/null || log_msg "Warning: Cannot create $dir"
done
progress_update 60

# -----------------------------
# Copy Alacritty config and fonts into hidden installer folder
cp -v "$ALACRITTY_CONFIG_DIR/alacritty.yml" "$HOME/.archcraft_installer/.config/alacritty/alacritty.yml" 2>&1 | tee -a "$LOG_FILE" || log_msg "Error copying Alacritty config"

# Fonts already installed locally; also copy to hidden installer folder
cp -rv "$FIRA_DIR/ttf" "$HOME/.archcraft_installer/.local/share/fonts/FiraCode" 2>&1 | tee -a "$LOG_FILE" || log_msg "Error copying Fira Code to hidden folder"

progress_update 65

# -----------------------------
# Optional: set default DE/WM session (Openbox)
progress_start "Setting Openbox as default session..."
sudo update-alternatives --install /usr/bin/x-session-manager x-session-manager /usr/bin/openbox-session 50 2>&1 | tee -a "$LOG_FILE" || log_msg "Error setting Openbox default session"
progress_update 70
# -----------------------------
# Flatpak + Flathub
progress_start "Installing Flatpak + Flathub..."
if ! sudo apt-get install -y flatpak 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error installing Flatpak"
fi

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a "$LOG_FILE" || log_msg "Error adding Flathub"
progress_update 80

# -----------------------------
# Snapd (optional)
progress_start "Installing Snapd..."
if ! sudo apt-get install -y snapd 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error installing snapd"
fi
progress_update 85

# -----------------------------
# Cleanup temporary files in hidden installer folder
progress_start "Cleaning up temporary files..."
rm -rf "$HOME/.archcraft_installer/limine.zip" 2>/dev/null
rm -rf "$HOME/.archcraft_installer/tmp" 2>/dev/null
progress_update 90

# -----------------------------
# Finalize installer
progress_start "Finalizing installation..."
progress_update 95

# Move all remaining installer-related items into hidden folder
mv -v "$HOME/archcraft_installer_backup" "$HOME/.archcraft_installer/" 2>/dev/null
mv -v "$HOME/archcraft_installer_export" "$HOME/.archcraft_installer/" 2>/dev/null
mv -v "$HOME/archcraft_installer_reports" "$HOME/.archcraft_installer/" 2>/dev/null
mv -v "$HOME/archcraft_openbox" "$HOME/.archcraft_installer/" 2>/dev/null
mv -v "$HOME/archcraft_installer.json" "$HOME/.archcraft_installer/" 2>/dev/null
mv -v "$HOME/archcraft_installer.log" "$HOME/.archcraft_installer/" 2>/dev/null
mv -v "$HOME/archcraft_install_errors.txt" "$HOME/.archcraft_installer/" 2>/dev/null
mv -v "$HOME/archcraft_installer_updated.sh" "$HOME/.archcraft_installer/" 2>/dev/null
progress_update 98

# -----------------------------
# Final progress bar
progress_end

# -----------------------------
# Notify user of log location
zenity --info \
    --title="Archcraft Installer Complete" \
    --text="Installation finished!\n\nAll error/warning logs are in:\n$HOME/.archcraft_installer/archcraft_install_errors.txt"

echo "Installer finished. Log file location: $HOME/.archcraft_installer/archcraft_install_errors.txt"
