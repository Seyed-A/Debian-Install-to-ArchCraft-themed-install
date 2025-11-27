#!/bin/bash

# ===============================
# Debian → Archcraft Openbox GUI Installer
# Self-contained, works on minimal/empty Debian
# Full Install
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

ESSENTIALS=(sudo wget git curl unzip xz tar build-essential cmake make meson ninja-build python3 python3-tk xprintidle)
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
  TRUE "Limine EFI" \
  TRUE "Screensaver (username flying text idle-time)" \
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
        "Limine EFI")
            zenity --info --text="Installing Limine EFI bootloader..."
            LIMINE_URL=$(curl -s https://api.github.com/repos/limine-bootloader/limine/releases/latest \
              | grep browser_download_url | grep x86_64-linux | cut -d '"' -f 4)
            wget -O ~/limine.zip "$LIMINE_URL"
            unzip ~/limine.zip -d ~/limine
            cd ~/limine
            if [[ -d /boot/efi ]]; then sudo ./limine-install.sh; fi
            ;;
        "Screensaver (username flying text idle-time)")
            zenity --info --text="Installing flying username screensaver (idle-time)..."

            # Ask user for inactivity timeout in minutes
            SC_TIMEOUT=$(zenity --entry --title="Screensaver Timeout" \
              --text="Enter inactivity timeout in minutes:" --entry-text="5")
            SC_TIMEOUT=${SC_TIMEOUT:-5}

            # Save timeout to dedicated config folder
            mkdir -p ~/.config/archcraft-screensaver
            echo "$SC_TIMEOUT" > ~/.config/archcraft-screensaver/config

            # Create flying text script
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

            # Create systemd user service
            mkdir -p ~/.config/systemd/user
            cat > ~/.config/systemd/user/archcraft-screensaver.service <<'EOF'
[Unit]
Description=Archcraft flying username screensaver (idle-time)

[Service]
Type=simple
ExecStart=/bin/bash -c '
CONFIG="$HOME/.config/archcraft-screensaver/config"
while true; do
    IDLE_MS=$(xprintidle)
    IDLE_MIN=$(cat "$CONFIG")
    THRESHOLD=$((IDLE_MIN*60*1000))
    if [ "$IDLE_MS" -ge "$THRESHOLD" ]; then
        # run screensaver
        ~/bin/username_flying_text.py
    fi
    sleep 5
done
'
Restart=always
EOF

            # Enable systemd service
            systemctl --user daemon-reload
            systemctl --user enable --now archcraft-screensaver.service
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
