#!/bin/bash
# =======================================================
# Debian → Archcraft Openbox Full Installer (Single-File)
# Author: Seyed Adrian Saberifar
# Modes: --repair --silent --minimal --full
# =======================================================

# ------------------ Logging ------------------
log() { echo -e "[INFO] $1"; }
err() { echo -e "[ERROR] $1"; }

# ------------------ Mode Detection ------------------
MODE="interactive"
for arg in "$@"; do
    case $arg in
        --repair) REPAIR=true ;;
        --silent) SILENT=true ;;
        --minimal) MINIMAL=true ;;
        --full) FULL=true ;;
        --help)
            echo "Usage: $0 [--repair] [--silent] [--minimal] [--full]"
            echo "  --repair  : reinstall all packages/components"
            echo "  --silent  : non-interactive, default options"
            echo "  --minimal : essential + Openbox + Plank only"
            echo "  --full    : install everything"
            exit 0 ;;
    esac
done

# ------------------ Helper Functions ------------------
ensure_pkg() {
    local pkg=$1
    if $REPAIR || ! dpkg -s "$pkg" &>/dev/null; then
        log "Installing missing package: $pkg"
        sudo apt -y install "$pkg" || err "Failed to install $pkg"
    else
        log "$pkg already installed, skipping..."
    fi
}

progress_start() {
    if [ -z "$SILENT" ]; then
        ( 
            echo "0" ; sleep 0.1
        ) | zenity --progress --title="Archcraft Installer" \
            --text="$1" --percentage=0 --auto-close --width=400 &
        PROG_PID=$!
    fi
}

progress_update() {
    if [ -z "$SILENT" ] && [ ! -z "$PROG_PID" ]; then
        echo "$1" | zenity --progress --title="Archcraft Installer" --percentage="$1" --no-cancel &
    fi
}

progress_end() {
    if [ ! -z "$PROG_PID" ]; then
        wait $PROG_PID 2>/dev/null
    fi
}

# ------------------ Essentials ------------------
ESSENTIALS=(sudo wget git curl unzip xz-utils tar build-essential cmake make meson ninja-build python3 python3-tk xprintidle zenity fastfetch)
for pkg in "${ESSENTIALS[@]}"; do
    ensure_pkg "$pkg"
done

# ------------------ GUI Welcome ------------------
if [ -z "$SILENT" ]; then
    zenity --info --title="Archcraft Installer" \
        --text="Welcome! This installer transforms Debian into Archcraft Openbox style.\nChoose components next."
fi

# ------------------ Component Selection ------------------
if [ -z "$SILENT" ]; then
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
        TRUE "Limine EFI" \
        TRUE "Screensaver (username flying text idle-time)" \
        --separator=",")
    IFS=',' read -ra SELECTION <<< "$COMPONENTS"
else
    # Silent/default: install all
    SELECTION=("Openbox + Plank" "XFCE utilities" "Themes + Fonts" "Flatpak + Flathub" "Snap" "Homebrew" "Limine EFI" "Screensaver (username flying text idle-time)")
fi

# ------------------ Install Selected Components ------------------
TOTAL=${#SELECTION[@]}
COUNT=0
for item in "${SELECTION[@]}"; do
    PERCENT=$(( COUNT * 100 / TOTAL ))
    progress_update "$PERCENT"
    case $item in
        "Openbox + Plank")
            log "Installing Openbox + Plank..."
            sudo apt update
            sudo apt -y install xorg openbox obconf plank ;;
        "XFCE utilities")
            log "Installing XFCE utilities..."
            sudo apt -y install xfce4 xfce4-goodies alacritty rofi nitrogen feh fastfetch kitty pcmanfm ;;
        "Themes + Fonts")
            log "Installing Themes and Fonts..."
            sudo apt -y install adwaita-icon-theme arc-theme papirus-icon-theme fonts-ubuntu fonts-font-awesome ;;
        "Flatpak + Flathub")
            log "Installing Flatpak + Flathub..."
            sudo apt -y install flatpak
            sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo ;;
        "Snap")
            log "Installing Snap..."
            sudo apt -y install snapd
            sudo systemctl enable --now snapd.socket
            sudo ln -s /var/lib/snapd/snap /snap 2>/dev/null || true ;;
        "Homebrew")
            log "Installing Homebrew..."
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || echo '')" ;;
        "Limine EFI")
            log "Installing Limine EFI bootloader..."
            LIMINE_URL=$(curl -s https://api.github.com/repos/limine-bootloader/limine/releases/latest \
                | grep browser_download_url | grep x86_64-linux | cut -d '"' -f 4)
            wget -O ~/limine.zip "$LIMINE_URL"
            unzip ~/limine.zip -d ~/limine
            cd ~/limine || continue
            if [[ -d /boot/efi ]]; then sudo ./limine-install.sh; fi ;;
        "Screensaver (username flying text idle-time)")
            if [ -z "$SILENT" ]; then
                SC_TIMEOUT=$(zenity --entry --title="Screensaver Timeout" \
                    --text="Enter inactivity timeout in minutes:" --entry-text="5")
            else
                SC_TIMEOUT=5
            fi
            SC_TIMEOUT=${SC_TIMEOUT:-5}
            mkdir -p ~/.config/archcraft-screensaver
            echo "$SC_TIMEOUT" > ~/.config/archcraft-screensaver/config
            mkdir -p ~/bin
            cat > ~/bin/username_flying_text.py <<'EOF'
#!/usr/bin/env python3
import tkinter as tk, random, os
root = tk.Tk()
root.attributes("-fullscreen", True)
root.configure(bg='black')
texts = []
colors = ['red','green','blue','yellow','cyan','magenta','white']
width = root.winfo_screenwidth()
height = root.winfo_screenheight()
username = os.environ.get("USER")
for i in range(20):
    txt = tk.Label(root, text=f"{username}\non Archcraft", fg=random.choice(colors),
                   bg='black', font=("Courier", random.randint(20,40)), justify='center')
    txt.place(x=random.randint(0,width), y=random.randint(0,height))
    dx = random.choice([-3,-2,-1,1,2,3])
    dy = random.choice([-3,-2,-1,1,2,3])
    texts.append((txt, dx, dy))
def move():
    for i, (lbl, dx, dy) in enumerate(texts):
        x = lbl.winfo_x() + dx
        y = lbl.winfo_y() + dy
        if x < 0 or x > width-200: dx *= -1
        if y < 0 or y > height-100: dy *= -1
        lbl.place(x=x, y=y)
        texts[i] = (lbl, dx, dy)
    root.after(50, move)
move()
root.mainloop()
EOF
            chmod +x ~/bin/username_flying_text.py
            mkdir -p ~/.config/systemd/user
            cat > ~/.config/systemd/user/archcraft-screensaver.service <<'EOF'
[Unit]
Description=Archcraft flying username screensaver
[Service]
Type=simple
ExecStart=/bin/bash -c '
CONFIG="$HOME/.config/archcraft-screensaver/config"
while true; do
    IDLE_MS=$(xprintidle)
    IDLE_MIN=$(cat "$CONFIG")
    THRESHOLD=$((IDLE_MIN*60*1000))
    if [ "$IDLE_MS" -ge "$THRESHOLD" ]; then
        ~/bin/username_flying_text.py
    fi
    sleep 5
done
'
Restart=always
EOF
            systemctl --user daemon-reload
            systemctl --user enable --now archcraft-screensaver.service ;;
    esac
    COUNT=$((COUNT + 1))
done
progress_end

# ------------------ Archcraft Dotfiles ------------------
log "Pulling Archcraft Openbox dotfiles..."
mkdir -p ~/.config
git clone https://github.com/archcraft-os/archcraft-openbox.git ~/archcraft-openbox
cp -r ~/archcraft-openbox/files/* ~/.config/ || true

# ------------------ Autostart Plank ------------------
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

# ------------------ Wallpapers + Font Cache ------------------
mkdir -p ~/Pictures/Wallpapers
cp -r ~/archcraft-openbox/files/wallpapers/* ~/Pictures/Wallpapers/ || true
fc-cache -fv

# ------------------ Cleanup ------------------
sudo apt -y autoremove
sudo apt -y clean

# ------------------ Completion ------------------
if [ -z "$SILENT" ]; then
    zenity --info --title="Installation Complete" --text="Debian → Archcraft Openbox transformation is complete!\nReboot to start your GUI."
else
    log "Installation complete! Reboot to start GUI."
fi
