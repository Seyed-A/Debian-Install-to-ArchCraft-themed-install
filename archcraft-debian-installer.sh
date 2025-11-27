#!/bin/bash
# =======================================================
# Debian → Archcraft Openbox Full Installer (Single-File)
# Author: Seyed Adrian Saberifar
# =======================================================

log() { echo -e "[INFO] $1"; }
err() { echo -e "[ERROR] $1"; }

# ------------------ Essential Packages ------------------
ESSENTIALS=(sudo wget git curl unzip xz-utils tar build-essential cmake make meson ninja-build python3 python3-tk xprintidle zenity fastfetch adwaita-icon-theme arc-theme papirus-icon-theme fonts-ubuntu fonts-font-awesome xfce4 xfce4-goodies alacritty rofi nitrogen feh kitty pcmanfm plank openbox obconf flatpak snapd)

log "Updating package lists..."
sudo apt update -y

for pkg in "${ESSENTIALS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        log "Installing missing package: $pkg"
        sudo apt -y install "$pkg"
    else
        log "$pkg already installed, skipping..."
    fi
done

# ------------------ Welcome ------------------
zenity --info --title="Debian → Archcraft Installer" \
  --text="Welcome! This installer will transform your Debian system into Archcraft Openbox style.\nAll essential dependencies are now installed."

# ------------------ Component Selection ------------------
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

# ------------------ Install Components ------------------
for item in "${SELECTION[@]}"; do
    case $item in
        "Openbox + Plank")
            zenity --info --text="Installing Openbox + Plank..."
            sudo apt -y install xorg openbox obconf plank
            ;;
        "XFCE utilities")
            zenity --info --text="Installing XFCE utilities..."
            sudo apt -y install xfce4 xfce4-goodies alacritty rofi nitrogen feh fastfetch kitty pcmanfm || true
            ;;
        "Themes + Fonts")
            zenity --info --text="Installing Themes and Fonts..."
            sudo apt -y install adwaita-icon-theme arc-theme papirus-icon-theme fonts-ubuntu fonts-font-awesome || true
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
            if [[ -n "$LIMINE_URL" ]]; then
                wget -O ~/limine.zip "$LIMINE_URL"
                unzip ~/limine.zip -d ~/limine
                if [[ -d /boot/efi ]]; then
                    cd ~/limine
                    sudo ./limine-install.sh
                fi
            else
                log "Limine download failed, skipping."
            fi
            ;;
        "Screensaver (username flying text idle-time)")
            zenity --info --text="Installing flying username screensaver..."
            SC_TIMEOUT=$(zenity --entry --title="Screensaver Timeout" \
              --text="Enter inactivity timeout in minutes:" --entry-text="5")
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
texts=[]
colors=['red','green','blue','yellow','cyan','magenta','white']
width=root.winfo_screenwidth()
height=root.winfo_screenheight()
username=os.environ.get("USER")
for i in range(20):
    txt=tk.Label(root,text=f"{username}\non Archcraft",fg=random.choice(colors),
                 bg='black',font=("Courier",random.randint(20,40)),justify='center')
    txt.place(x=random.randint(0,width),y=random.randint(0,height))
    dx=random.choice([-3,-2,-1,1,2,3])
    dy=random.choice([-3,-2,-1,1,2,3])
    texts.append((txt,dx,dy))
def move():
    for i,(lbl,dx,dy) in enumerate(texts):
        x=lbl.winfo_x()+dx
        y=lbl.winfo_y()+dy
        if x<0 or x>width-200: dx*=-1
        if y<0 or y>height-100: dy*=-1
        lbl.place(x=x,y=y)
        texts[i]=(lbl,dx,dy)
    root.after(50,move)
move()
root.mainloop()
EOF
            chmod +x ~/bin/username_flying_text.py

            mkdir -p ~/.config/systemd/user
            cat > ~/.config/systemd/user/archcraft-screensaver-wrapper.sh <<'EOF'
#!/bin/bash
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
EOF
            chmod +x ~/.config/systemd/user/archcraft-screensaver-wrapper.sh

            cat > ~/.config/systemd/user/archcraft-screensaver.service <<'EOF'
[Unit]
Description=Archcraft flying username screensaver (idle-time)

[Service]
Type=simple
ExecStart=%h/.config/systemd/user/archcraft-screensaver-wrapper.sh
Restart=always
EOF

            systemctl --user daemon-reload
            systemctl --user enable --now archcraft-screensaver.service
            ;;
    esac
done

# ------------------ Archcraft Dotfiles ------------------
zenity --info --text="Setting up Archcraft Openbox dotfiles..."
mkdir -p ~/.config
git clone https://github.com/archcraft-os/archcraft-openbox.git ~/archcraft-openbox || true
if [[ -d ~/archcraft-openbox/files ]]; then
    cp -r ~/archcraft-openbox/files/* ~/.config/
fi

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
if [[ -d ~/archcraft-openbox/files/wallpapers ]]; then
    cp -r ~/archcraft-openbox/files/wallpapers/* ~/Pictures/Wallpapers/
fi
fc-cache -fv

# ------------------ Cleanup ------------------
sudo apt -y autoremove
sudo apt -y clean

zenity --info --title="Installation Complete" --text="Debian → Archcraft Openbox transformation is complete!\nReboot to start your GUI."
