#!/bin/bash
# =======================================================
# Debian → Archcraft Openbox Full Installer (Single-File)
# Author: Seyed Adrian Saberifar (Modified)
# Features: GUI progress bars, clickable EFI selection, single sudo password, error log
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
# Ask for sudo once upfront
if sudo -v; then
    # Keep-alive: update existing sudo timestamp until script finishes
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
else
    echo "This script requires sudo access. Exiting."
    exit 1
fi

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
progress_start "Installing Limine EFI Bootloader..."
progress_update 65

# -----------------------------
# Detect EFI partitions for clickable selection
EFI_DEVICES=($(lsblk -o NAME,LABEL,FSTYPE,MOUNTPOINT | grep -i 'vfat\|efi' | awk '{print "/dev/"$1 " (" $2 ")"}'))

if [ ${#EFI_DEVICES[@]} -eq 0 ]; then
    EFI_CHOICE=$(zenity --entry \
        --title="Limine EFI Installer" \
        --text="No EFI partitions auto-detected. Enter EFI partition manually:" \
        --entry-text "/dev/sda1")
else
    EFI_CHOICE=$(zenity --list \
        --title="Select EFI Partition" \
        --text="Choose EFI partition for Limine" \
        --column="EFI Devices" "${EFI_DEVICES[@]}")
fi

if [ -z "$EFI_CHOICE" ]; then
    log_msg "User did not select an EFI partition"
    zenity --error --text="EFI partition not selected. Limine installation skipped."
else
    echo "Selected EFI partition: $EFI_CHOICE"
fi

progress_update 70

# -----------------------------
# Limine installation
LIMINE_URL="https://github.com/limine-bootloader/limine/releases/download/4.16/limine-4.16.zip"
LIMINE_ZIP="$HOME/limine.zip"
LIMINE_DIR="$HOME/limine"

# Download Limine
if ! wget -O "$LIMINE_ZIP" "$LIMINE_URL" 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error downloading Limine"
fi

# Unzip Limine
if unzip -o "$LIMINE_ZIP" -d "$LIMINE_DIR" 2>&1 | tee -a "$LOG_FILE"; then
    cd "$LIMINE_DIR" || log_msg "Cannot cd to $LIMINE_DIR"
    # Install Limine (requires EFI choice)
    if [ -n "$EFI_CHOICE" ]; then
        sudo make install 2>&1 | tee -a "$LOG_FILE" || log_msg "Error installing Limine"
    fi
else
    log_msg "Limine unzip failed"
fi

progress_update 75
# -----------------------------
# Flatpak + Flathub installation
progress_start "Installing Flatpak + Flathub..."
if ! sudo apt-get install -y flatpak 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error installing Flatpak"
fi
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a "$LOG_FILE" || log_msg "Error adding Flathub"
progress_update 80

# -----------------------------
# Snap installation
progress_start "Installing Snap..."
if ! sudo apt-get install -y snapd 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "Error installing snapd"
fi
progress_update 82

# -----------------------------
# Homebrew installation
progress_start "Installing Homebrew..."
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOG_FILE" || log_msg "Homebrew install failed"

# Configure Homebrew for the current shell
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

progress_update 85

# -----------------------------
# Fonts and themes installation
progress_start "Installing Themes and Fonts..."
mkdir -p "$HOME/.local/share/fonts" 2>/dev/null || log_msg "Cannot create ~/.local/share/fonts"

# Attempt to install Ubuntu fonts
if ! sudo apt-get install -y fonts-ubuntu 2>&1 | tee -a "$LOG_FILE"; then
    log_msg "fonts-ubuntu not available or failed"
fi
progress_update 90

# -----------------------------
# Final setup
progress_start "Finalizing installation..."
# Reload font cache
fc-cache -fv 2>&1 | tee -a "$LOG_FILE" || log_msg "Font cache update failed"

# Notify user of log file location
zenity --info --title="Installation Complete" \
    --text="Archcraft Openbox installation is complete.\n\nAll errors and warnings are logged here:\n$LOG_FILE"

progress_update 100
progress_end
