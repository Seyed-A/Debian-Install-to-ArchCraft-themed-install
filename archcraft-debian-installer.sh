#!/bin/bash
# =======================================================
# Debian → Archcraft Openbox Full Installer (Single-File)
# Author: Seyed Adrian Saberifar
# =======================================================

log() { echo "[INFO] $1"; }
err() { echo "[ERROR] $1"; }

# ------------------ Repair Mode ------------------
REPAIR_MODE=0
if [[ "$1" == "--repair" ]]; then
    REPAIR_MODE=1
    zenity --info --text="Repair mode: all components and packages will be reinstalled."
fi

# ------------------ Essential Packages ------------------
ESSENTIALS=(sudo wget git curl unzip xz-utils tar build-essential cmake make meson ninja-build python3 python3-tk xprintidle zenity fastfetch adwaita-icon-theme arc-theme papirus-icon-theme fonts-ubuntu fonts-font-awesome xfce4 xfce4-goodies alacritty rofi nitrogen feh kitty pcmanfm plank openbox obconf flatpak snapd)

TOTAL_STEPS=${#ESSENTIALS[@]}
STEP=0

(
for pkg in "${ESSENTIALS[@]}"; do
    STEP=$((STEP+1))
    PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
    if [[ $REPAIR_MODE -eq 1 ]] || ! dpkg -s "$pkg" &>/dev/null; then
        echo "$PERCENT"
        echo "# Installing/reinstalling $pkg..."
        sudo apt -y install --reinstall "$pkg" >/dev/null 2>&1
    else
        echo "$PERCENT"
        echo "# $pkg already installed, skipping..."
    fi
    sleep 0.2
done

# ------------------ Openbox + Plank ------------------
STEP=$((STEP+1))
PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
echo "$PERCENT"
echo "# Installing Openbox + Plank..."
sudo apt -y install --reinstall xorg openbox obconf plank >/dev/null 2>&1

# ------------------ XFCE Utilities ------------------
STEP=$((STEP+1))
PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
echo "$PERCENT"
echo "# Installing XFCE utilities..."
sudo apt -y install --reinstall xfce4 xfce4-goodies alacritty rofi nitrogen feh kitty pcmanfm >/dev/null 2>&1

# ------------------ Flatpak + Flathub ------------------
STEP=$((STEP+1))
PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
echo "$PERCENT"
echo "# Installing Flatpak + Flathub..."
sudo apt -y install --reinstall flatpak >/dev/null 2>&1
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1

# ------------------ Snap ------------------
STEP=$((STEP+1))
PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
echo "$PERCENT"
echo "# Installing Snap..."
sudo apt -y install --reinstall snapd >/dev/null 2>&1
sudo systemctl enable --now snapd.socket >/dev/null 2>&1
sudo ln -s /var/lib/snapd/snap /snap 2>/dev/null || true

# ------------------ Homebrew ------------------
STEP=$((STEP+1))
PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
echo "$PERCENT"
echo "# Installing Homebrew..."
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || echo '')"

# ------------------ Limine EFI ------------------
STEP=$((STEP+1))
PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
echo "$PERCENT"
echo "# Installing Limine EFI..."
LIMINE_URL=$(curl -s https://api.github.com/repos/limine-bootloader/limine/releases/latest \
              | grep browser_download_url | grep x86_64-linux | cut -d '"' -f 4)
if [[ -n "$LIMINE_URL" ]]; then
    wget -O ~/limine.zip "$LIMINE_URL" >/dev/null 2>&1
    unzip ~/limine.zip -d ~/limine >/dev/null 2>&1
    if [[ -d /boot/efi ]]; then
        cd ~/limine && sudo ./limine-install.sh >/dev/null 2>&1 || log "Limine install failed"
    fi
fi

# ------------------ Screensaver ------------------
STEP=$((STEP+1))
PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
echo "$PERCENT"
echo "# Installing flying username screensaver..."
SC_TIMEOUT=$(zenity --entry --title="Screensaver Timeout" --text="Enter inactivity timeout in minutes:" --entry-text="5")
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
        ~/bin/username_flying_text.py
    fi
    sleep 5
done
'
Restart=always
EOF
systemctl --user daemon-reload
systemctl --user enable --now archcraft-screensaver.service

# ------------------ Archcraft dotfiles ------------------
STEP=$((STEP+1))
PERCENT=$(( STEP * 100 / TOTAL_STEPS ))
echo "$PERCENT"
echo "# Setting up Archcraft Openbox dotfiles..."
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

# ------------------ Wallpapers + font cache ------------------
mkdir -p ~/Pictures/Wallpapers
cp -r ~/archcraft-openbox/files/wallpapers/* ~/Pictures/Wallpapers/ || true
fc-cache -fv

echo "100"
echo "# Installation complete!"
) | zenity --progress \
    --title="Archcraft Debian Installer" \
    --text="Starting installation..." \
    --percentage=0 \
    --auto-close \
    --width=600

zenity --info --title="Installation Complete" --text="Debian → Archcraft Openbox transformation is complete!\nReboot to start your GUI."
