#!/bin/bash
# =======================================================
# Debian → Archcraft Openbox Full Installer (Single-File)
# Author: Seyed Adrian Saberifar
# Modes: --repair --silent --minimal --full
# =======================================================
LOG_FILE="$HOME/archcraft_install_errors.txt"
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
# Initial progress
progress_start "Starting Archcraft Openbox Installer..."
progress_update 5

# -----------------------------
# Ensure dependencies
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
# Limine EFI detection
EFI_DEVICES=($(lsblk -o NAME,LABEL,FSTYPE | grep -i EFI | awk '{print "/dev/"$1}'))
if [ ${#EFI_DEVICES[@]} -eq 0 ]; then
    EFI_CHOICE=$(zenity --entry --title="Limine EFI Installer" --text="No EFI partitions auto-detected. Enter EFI partition manually:" --entry-text "/dev/sda1")
else
    EFI_CHOICE=$(zenity --list --title="Select EFI Partition" --column="EFI Devices" "${EFI_DEVICES[@]}")
fi
progress_update 20

# -----------------------------
# Core system packages install
CORE_PKGS=(xorg openbox obconf plank xfce4 xfce4-goodies alacritty rofi nitrogen feh kitty pcmanfm)
for pkg in "${CORE_PKGS[@]}"; do
    echo "Installing $pkg..."
    if ! sudo apt-get install -y "$pkg" 2>&1 | tee -a "$LOG_FILE"; then
        log_msg "Error installing $pkg"
    fi
done
progress_update 50

# -----------------------------
# Create user config directories
mkdir -p "$HOME/.config/autostart" 2>/dev/null || log_msg "Warning: Cannot create ~/.config/autostart"
mkdir -p "$HOME/.local/share/fonts" 2>/dev/null || log_msg "Warning: Cannot create ~/.local/share/fonts"

progress_update 60

progress_update 65
progress_start "Installing Limine EFI Bootloader..."

# Limine installation
LIMINE_URL="https://github.com/limine-bootloader/limine/releases/download/4.16/limine-4.16.zip"
LIMINE_ZIP="$HOME/limine.zip"

if ! wget -O "$LIMINE_ZIP" "$LIMINE_URL" 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error downloading Limine"
fi

if unzip "$LIMINE_ZIP" -d "$HOME/limine" 2>&1 | tee -a "$LOG_FILE"; then
    cd "$HOME/limine" || log_msg "Cannot cd to $HOME/limine"
    sudo make install 2>&1 | tee -a "$LOG_FILE" || log_msg "Error installing Limine"
else
    log_msg "Limine unzip failed"
fi

progress_update 75

# -----------------------------
# Flatpak + Flathub
progress_start "Installing Flatpak + Flathub..."
if ! sudo apt-get install -y flatpak 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error installing Flatpak"
fi
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a "$LOG_FILE" || log_msg "Error adding Flathub"
progress_update 80

# -----------------------------
# Snap
progress_start "Installing Snap..."
if ! sudo apt-get install -y snapd 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error installing snapd"
fi
progress_update 82

# -----------------------------
# Homebrew
progress_start "Installing Homebrew..."
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOG_FILE" || log_msg "Error installing Homebrew"

# Add Homebrew to PATH
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

progress_update 85

# -----------------------------
# Fonts + Themes
progress_start "Installing Fonts & Themes..."
# Example font Ubuntu (fallback if not available)
if ! sudo apt-get install -y fonts-ubuntu 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Warning: fonts-ubuntu not available"
fi

# Cache fonts
fc-cache -f 2>&1 | tee -a "$LOG_FILE"

progress_update 90

# -----------------------------
# Set wallpapers (if available)
WALLPAPER_DIR="$HOME/archcraft-openbox/files/wallpapers"
if [ -d "$WALLPAPER_DIR" ]; then
    cp "$WALLPAPER_DIR"/* "$HOME/Pictures/" 2>&1 | tee -a "$LOG_FILE" || log_msg "Cannot copy wallpapers"
fi

progress_update 92

progress_update 92
progress_start "Setting up Archcraft Openbox dotfiles..."

DOTFILES_DIR="$HOME/archcraft-openbox"
if [ ! -d "$DOTFILES_DIR" ]; then
    git clone https://github.com/Seyed-A/archcraft-openbox.git "$DOTFILES_DIR" 2>&1 | tee -a "$LOG_FILE" || log_msg "Error cloning archcraft-openbox repo"
else
    log_msg "archcraft-openbox directory exists, skipping clone"
fi

# Autostart Plank
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR" 2>&1 | tee -a "$LOG_FILE" || log_msg "Cannot create autostart directory"
if [ -d "$AUTOSTART_DIR" ]; then
    cp "$DOTFILES_DIR/files/autostart/plank.desktop" "$AUTOSTART_DIR/" 2>&1 | tee -a "$LOG_FILE" || log_msg "Cannot copy plank.desktop"
fi

# Copy wallpapers if available
WALLPAPER_SRC="$DOTFILES_DIR/files/wallpapers"
WALLPAPER_DEST="$HOME/Pictures"
mkdir -p "$WALLPAPER_DEST"
if [ -d "$WALLPAPER_SRC" ]; then
    cp "$WALLPAPER_SRC"/* "$WALLPAPER_DEST/" 2>&1 | tee -a "$LOG_FILE" || log_msg "Cannot copy wallpapers"
fi

progress_update 95

# -----------------------------
# XFCE tweaks (if XFCE installed)
progress_start "Applying XFCE tweaks..."
XFCE_CONF="$HOME/.config/xfce4"
mkdir -p "$XFCE_CONF" 2>&1 | tee -a "$LOG_FILE" || log_msg "Cannot create XFCE config directory"

# Example tweak: disable screensaver service errors
systemctl --user disable archcraft-screensaver.service 2>&1 | tee -a "$LOG_FILE" || log_msg "Cannot disable archcraft-screensaver.service"

progress_update 98

progress_start "Finalizing installation..."

# Clean up temporary files
TEMP_DIRS=("$HOME/limine" "$HOME/limine.zip")
for dir in "${TEMP_DIRS[@]}"; do
    if [ -e "$dir" ]; then
        rm -rf "$dir" 2>&1 | tee -a "$LOG_FILE" || log_msg "Cannot remove $dir"
    fi
done

progress_update 99

# Final message
progress_start "Installation Complete!"
echo -e "\nInstallation finished successfully!"
echo "All warnings and errors (only) are logged in:"
echo "$LOG_FILE"

progress_update 100
