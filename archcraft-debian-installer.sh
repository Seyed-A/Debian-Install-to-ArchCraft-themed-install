#!/bin/bash

# ===============================
# Debian → Archcraft Openbox GUI Installer
# Self-contained, works on minimal/empty Debian
# Minimal Install
# ===============================

log() { echo -e "[INFO] $1"; }
err() { echo -e "[ERROR] $1"; }

# ----- Step 0: Ensure essential commands -----
ensure_command() {
    local cmd=$1
    local pkg=${2:-$cmd}
    if ! command -v "$cmd" &>/dev/null; then
        log "$cmd not found. Installing $pkg..."
        sudo apt update -y
        sudo apt -y install "$pkg" || err "Failed to install $pkg"
    fi
}

ESSENTIALS=(sudo wget git curl unzip xz tar build-essential cmake make meson ninja-build)
for cmd in "${ESSENTIALS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        if [[ $cmd == "sudo" ]]; then
            log "sudo not found. Installing sudo (requires root)..."
            su -c "apt update && apt -y install sudo" || err "Cannot install sudo"
        else
            ensure_command "$cmd"
        fi
    fi
done

# ----- Step 1: Ensure GUI toolkit -----
ensure_command zenity

# ----- Step 2: Welcome dialog -----
zenity --info --title="Debian → Archcraft Installer" \
  --text="Welcome! This installer will transform your Debian system into Archcraft Openbox style.\nIt works on empty/minimal Debian installs."

# ----- Step 3: Select components -----
COMPONENTS=$(zenity --list --checklist \
  --title="Select components to install" \
  --text="Choose what to install" \
  --column="Install" --column="Component" \
  TRUE "Openbox + Plank" \
  TRUE "XFCE utilities" \
  TRUE "Themes + Fonts" \
  TRUE "Flatpak + Flathub" \
  TRUE "Snap" \
  TRUE "Homebrew" \
  --separator=",")

IFS=',' read -ra SELECTION <<< "$COMPONENTS"

# ----- Step 4: Install selected components -----
for item in "${SELECTION[@]}"; do
    case $item in
        "Openbox + Plank")
            zenity --info --text="Installing Openbox + Plank..."
            sudo apt update
            sudo apt -y install xorg openbox obconf plank || err "Failed Openbox/Plank"
            ;;
        "XFCE utilities")
            zenity --info --text="Installing XFCE utilities..."
            sudo apt -y install xfce4 xfce4-goodies alacritty rofi nitrogen feh neofetch kitty pcmanfm || true
            ;;
        "Themes + Fonts")
            zenity --info --text="Installing Themes and Fonts..."
            sudo apt -y install adwaita-icon-theme arc-theme papirus-icon-theme ttf-ubuntu-font-family ttf-font-awesome || true
            ;;
        "Flatpak + Flathub")
            zenity --info --text="Installing Flatpak and Flathub..."
            sudo apt -y install flatpak
            sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
            ;;
        "Snap")
            zenity --info --text="Installing Snap..."
            sudo apt -y install snapd
            sudo systemctl enable --now snapd.socket
            sudo ln -s /var/lib/snapd/snap /snap 2>/dev/null || true
            ;;
        "Homebrew")
            zenity --info --text="Installing Homebrew..."
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || echo '')"
            ;;
    esac
done

# ----- Step 5: Pull Archcraft Openbox dotfiles -----
zenity --info --text="Setting up Archcraft Openbox dotfiles..."
mkdir -p ~/.config
git clone https://github.com/archcraft-os/archcraft-openbox.git ~/archcraft-openbox
cp -r ~/archcraft-openbox/files/* ~/.config/

# ----- Step 6: Autostart Plank -----
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/plank.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
Comment=Start Plank dock
EOL

# ----- Step 7: Wallpapers + font cache -----
mkdir -p ~/Pictures/Wallpapers
cp -r ~/archcraft-openbox/files/wallpapers/* ~/Pictures/Wallpapers/ || true
fc-cache -fv

# ----- Step 8: Cleanup -----
sudo apt -y autoremove
sudo apt -y clean

zenity --info --title="Installation Complete" --text="Debian → Archcraft Openbox transformation is complete!\nReboot to start your GUI."
