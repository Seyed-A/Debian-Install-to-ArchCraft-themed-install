# 🚀 Archcraft Debian Installer

This repository provides an interactive installer to transform a minimal Debian system into an Archcraft Openbox style setup. The installer asks which packages and components you want at the start, so you can do a minimal or full installation in one go.

> Quick note: The `.sh` script and `.desktop` launcher file are functionally equivalent. This README covers the `.sh` script.

---

## Quick Install (Single Command)

You can run the installer directly without cloning the repository:

### Using wget

```bash
bash -c "$(wget -qO- https://github.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/raw/main/archcraft-debian-installer.sh)"
```

### Using curl

```bash
bash -c "$(curl -fsSL https://github.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/raw/main/archcraft-debian-installer.sh)"
```

> This will download and execute the installer in one step. You will be prompted to select which components to install.

> Note: These commands always fetch and run the current version of the script from GitHub.  
> If you have already run the latest version, you **do not need to run it again** unless there is a new update in the repository.

---

## Full Installation Tutorial (via Git Clone)

1. **Clone the repository**

```bash
git clone https://github.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install.git
```

2. **Navigate to the repository folder**

```bash
cd Debian-Install-to-ArchCraft-themed-install
```

3. **Make the installer executable**

```bash
chmod +x archcraft-debian-installer.sh
```

4. **Run the installer**

```bash
./archcraft-debian-installer.sh
```

> At the start, you will choose which components to install, such as Openbox + Plank, XFCE utilities, themes/fonts, Flatpak, Snap, Homebrew, Limine EFI, and the screensaver.

5. **Optional cleanup**

After installation, you can delete the cloned repository:

```bash
cd ..
rm -rf Debian-Install-to-ArchCraft-themed-install
```

---

## Using the `.desktop` File

You can also launch the installer using the `.desktop` file:

```bash
https://github.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/blob/main/archcraft-debian-installer.desktop
```

> This will execute the same installer as the `.sh` script.

---

## What the Installer Can Do

The installer lets you optionally install and configure:

### Essential Tools

* sudo, wget, git, curl, unzip, xz, tar, build-essential, cmake, make, meson, ninja-build, zenity, python3, python3-tk, xprintidle

### Openbox + Plank

* xorg, openbox, obconf, plank

### XFCE Utilities

* xfce4, xfce4-goodies, alacritty, rofi, nitrogen, feh, neofetch, kitty, pcmanfm

### Themes and Fonts

* adwaita-icon-theme, arc-theme, papirus-icon-theme, ttf-ubuntu-font-family, ttf-font-awesome

### Flatpak + Flathub

* flatpak, Flathub repository

### Snap

* snapd (with snapd.socket enabled)

### Homebrew

* Homebrew package manager for Linux

### Archcraft Dotfiles and GUI Setup

* Archcraft Openbox dotfiles
* Autostart Plank dock
* Wallpapers and font cache setup

### Optional Full Install Components

* Limine EFI bootloader
* Idle-time flying username screensaver (with customizable timeout)

---

## Notes

* The installer supports both **interactive GUI mode** via `zenity` and a **silent mode** for scripting.
  | Option      | Description                                                           | Behavior                                                                                                                                                    |
| ----------- | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--repair`  | Reinstalls **all components and packages**, even if already installed | Overrides skip checks, reinstalls essentials, GUI, utilities, themes, fonts, Flatpak, Snap, Homebrew, Limine, screensaver, dotfiles, wallpapers, font cache |
| `--silent`  | Non-interactive install; **skips all zenity prompts**                 | Runs all steps automatically with default choices; e.g., default screensaver timeout, installs all components without asking user                           |
| `--minimal` | Installs only **essential packages + Openbox + Plank + dotfiles**     | Skips XFCE utilities, Flatpak, Snap, Homebrew, Limine, screensaver, wallpapers                                                                              |
| `--full`    | Installs **everything**                                               | Same as default full installer                                                                                                                              |
| `--help`    | Shows usage instructions                                              | Prints a brief description of each mode and exits                                                                                                           |

* Errors can be optionally reported to GitHub if `gh` CLI is installed and authenticated.
* You can rollback system state using the backup created during installation.

🎉 Enjoy transforming your Debian system into Archcraft Openbox style!
