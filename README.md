# 🚀 Archcraft Debian Installer

## Quick Install (Single Command)

You can run the installer directly without cloning the repository using one of these single-command methods:

### Using wget

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/main/archcraft-debian-installer.sh)"
```

### Using curl

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install/main/archcraft-debian-installer.sh)"
```

These commands will download and execute the installer in one step, with no leftover files.

---

## Full Installation Tutorial (via Git Clone)

You can install the Archcraft Debian Installer directly from GitHub using the following steps:

1. **Clone the repository**

```bash
git clone https://github.com/Seyed-A/Debian-Install-to-ArchCraft-themed-install.git
```

2. **Navigate to the repository folder**

```bash
cd Debian-Install-to-ArchCraft-themed-install
```

3. **Make the installer script executable**

```bash
chmod +x archcraft-debian-installer.sh
```

4. **Run the installer**

```bash
./archcraft-debian-installer.sh
```

5. **Optional cleanup**
   After installation, you can delete the cloned repository if you like:

```bash
cd ..
rm -rf Debian-Install-to-ArchCraft-themed-install
```

---

## Quick Installation (Single File Method)

To turn the script into an executable "app" and run it, follow these steps:

1. **Make it executable**
   Open a terminal in the directory where the script is located and run:

```bash
chmod +x archcraft-debian-installer.sh
```

2. **Run the installer**
   Still in the same directory, launch the script:

```bash
./archcraft-debian-installer.sh
```

🎉 That’s it! The installer will guide you through transforming your Debian system into Archcraft Openbox style with a full GUI.

Enjoy! 🙂
