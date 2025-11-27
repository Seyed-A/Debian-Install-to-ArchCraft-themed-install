# 🚀 Archcraft Debian Installer

Quick note that the .sh and the .desktop files are the same but this tutorial only covers .sh.

## Quick Install (Single Command)

You can run the installer directly without cloning the repository using one of these single-command methods:

### Minimalist Install (Single Command)

bash -c "$(wget -qO- https://raw.githubusercontent.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/main/archcraft-debian-installer.sh)"

bash -c "$(curl -fsSL https://raw.githubusercontent.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/main/archcraft-debian-installer.sh)"

### Full Install (Single Command)

bash -c "$(wget -qO- https://raw.githubusercontent.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/main/archcraft-debian-installer-full.sh)"

bash -c "$(curl -fsSL https://raw.githubusercontent.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/main/archcraft-debian-installer-full.sh)"

These commands will download and execute the installer in one step, with no leftover files.

---

## Full Installation Tutorial (via Git Clone)

You can install the Archcraft Debian Installer directly from GitHub using the following steps:

1. **Clone the repository**

git clone https://github.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install.git

2. **Navigate to the repository folder**

cd Debian-Install-to-ArchCraft-themed-install

3. **Make the installer scripts executable**

chmod +x archcraft-debian-installer.sh
OR
chmod +x archcraft-debian-installer-full.sh

4. **Run Minimalist or Full installer**

* Minimalist install:

./archcraft-debian-installer.sh

* Full install:

./archcraft-debian-installer-full.sh

5. **Optional cleanup**

After installation, you can delete the cloned repository if you like:

cd ..
rm -rf Debian-Install-to-ArchCraft-themed-install

---

## Quick Installation (Single File Method)

To turn the scripts into executables and run them, follow these steps:

1. **Make them executable**

Open a terminal in the directory where the scripts are located and run:

chmod +x archcraft-debian-installer.sh
chmod +x archcraft-debian-installer-full.sh

2. **Run the installer**

Still in the same directory, launch the script of your choice:

./archcraft-debian-installer.sh   # Minimalist install
./archcraft-debian-installer-full.sh  # Full install

🎉 The installer will guide you through transforming your Debian system into Archcraft Openbox style with a full GUI.

Enjoy! 🙂

---

## Packages and Components Installed

The installer scripts install the following packages and components:

### Minimalist Install

#### Essential Tools

* sudo
* wget
* git
* curl
* unzip
* xz
* tar
* build-essential
* cmake
* make
* meson
* ninja-build
* zenity
* python3
* python3-tk
* xprintidle

#### Openbox + Plank

* xorg
* openbox
* obconf
* plank

#### XFCE Utilities

* xfce4
* xfce4-goodies
* alacritty
* rofi
* nitrogen
* feh
* neofetch
* kitty
* pcmanfm

#### Themes and Fonts

* adwaita-icon-theme
* arc-theme
* papirus-icon-theme
* ttf-ubuntu-font-family
* ttf-font-awesome

#### Flatpak + Flathub

* flatpak
* Flathub repository

#### Snap

* snapd (with snapd.socket enabled)

#### Homebrew

* Homebrew package manager for Linux

#### Archcraft Dotfiles and GUI Setup

* Archcraft Openbox dotfiles
* Autostart Plank dock
* Wallpapers and font cache setup

### Full Install Only

#### Limine EFI Bootloader

* Limine EFI (installed from GitHub release)

#### Screensaver

* Idle-time flying username screensaver
  * Customizable inactivity timeout
  * Displays username on top and "on Archcraft" below in floating text
