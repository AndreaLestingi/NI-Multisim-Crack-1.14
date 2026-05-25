#!/bin/bash
# Uninstall script for NI Multisim 14.0
# Removes Wine prefix, desktop entries, and cleans up

set -e

echo "========================================"
echo "  NI Multisim 14.0 Uninstaller"
echo "========================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ──────────────────────────────────────────────
# DETECT DISTRO FAMILY
# ──────────────────────────────────────────────
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID,,}"
    DISTRO_ID_LIKE="${ID_LIKE,,}"
  else
    echo "❌ Cannot detect distribution."
    DISTRO_FAMILY="unknown"
    return
  fi

  if [[ "$DISTRO_ID" == "arch" || "$DISTRO_ID_LIKE" == *"arch"* ]]; then
    DISTRO_FAMILY="arch"
  elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" ||
    "$DISTRO_ID_LIKE" == *"debian"* || "$DISTRO_ID" == "linuxmint" ]]; then
    DISTRO_FAMILY="debian"
  elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_ID_LIKE" == *"fedora"* ]]; then
    DISTRO_FAMILY="fedora"
  elif [[ "$DISTRO_ID" == "opensuse"* || "$DISTRO_ID_LIKE" == *"suse"* ]]; then
    DISTRO_FAMILY="suse"
  else
    DISTRO_FAMILY="unknown"
  fi
}

detect_distro

# ──────────────────────────────────────────────
# CHECK IF MULTISIM IS INSTALLED
# ──────────────────────────────────────────────
WINEPREFIX="$HOME/.multisim32"

if [ ! -d "$WINEPREFIX" ]; then
    echo -e "${YELLOW}⚠️  Wine prefix not found at $WINEPREFIX${NC}"
    echo "Multisim may not be installed or was already removed."
    read -p "Continue cleaning any residual files? [y/N]: " continue_clean
    if [[ ! "$continue_clean" =~ ^[Yy]$ ]]; then
        echo "Exiting."
        exit 0
    fi
fi

echo -e "${YELLOW}This will remove:${NC}"
echo "  - Wine prefix: $WINEPREFIX"
echo "  - Desktop launchers for Multisim"
echo "  - Application menu entries"
echo "  - Download cache (if any)"
echo

read -p "Are you sure you want to uninstall NI Multisim 14.0? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo

# ──────────────────────────────────────────────
# KILL ANY RUNNING WINE PROCESSES
# ──────────────────────────────────────────────
echo "Stopping any running Wine processes..."
if [ -d "$WINEPREFIX" ]; then
    WINEPREFIX="$WINEPREFIX" wineserver -k 2>/dev/null || true
fi
pkill -f "wine" 2>/dev/null || true
pkill -f "Multisim" 2>/dev/null || true
sleep 2

# ──────────────────────────────────────────────
# REMOVE WINE PREFIX
# ──────────────────────────────────────────────
if [ -d "$WINEPREFIX" ]; then
    echo "Removing Wine prefix directory..."
    rm -rf "$WINEPREFIX"
    echo -e "${GREEN}✅ Wine prefix removed.${NC}"
else
    echo "Wine prefix not found."
fi

# ──────────────────────────────────────────────
# REMOVE DESKTOP ENTRIES
# ──────────────────────────────────────────────
echo "Removing desktop launchers..."

# Remove .desktop files
find ~/.local/share/applications -name "*Multisim*" -type f -delete 2>/dev/null || true
find ~/.local/share/applications -name "*Circuit Design*" -type f -delete 2>/dev/null || true
find ~/.local/share/applications -name "*National Instruments*" -type f -delete 2>/dev/null || true
find ~/.local/share/applications -name "*NI*Multisim*" -type f -delete 2>/dev/null || true

# Remove wine-specific application entries
rm -rf ~/.local/share/applications/wine/Programs/National\ Instruments 2>/dev/null || true
rm -rf ~/.local/share/applications/wine/Programs/NI\ Multisim* 2>/dev/null || true

# Update desktop database
update-desktop-database ~/.local/share/applications 2>/dev/null || true

echo -e "${GREEN}✅ Desktop entries removed.${NC}"

# ──────────────────────────────────────────────
# REMOVE ICONS/CACHE
# ──────────────────────────────────────────────
echo "Removing icons and cache..."
rm -rf ~/.local/share/icons/hicolor/*/apps/*multisim* 2>/dev/null || true
rm -rf ~/.cache/wine 2>/dev/null || true
rm -rf /tmp/multisim-install.log 2>/dev/null || true
rm -rf /tmp/activator.log 2>/dev/null || true

# ──────────────────────────────────────────────
# OPTIONAL: REMOVE WINE PACKAGES
# ──────────────────────────────────────────────
echo
read -p "Do you also want to remove Wine and winetricks packages? [y/N]: " remove_wine
if [[ "$remove_wine" =~ ^[Yy]$ ]]; then
    echo "Removing Wine packages..."
    
    case "$DISTRO_FAMILY" in
        arch)
            sudo pacman -Rns --noconfirm wine-stable wine winetricks 2>/dev/null || true
            ;;
        debian)
            sudo apt-get remove --purge -y wine wine32 wine64 winetricks 2>/dev/null || true
            sudo apt-get autoremove -y
            ;;
        fedora)
            sudo dnf remove -y wine winetricks 2>/dev/null || true
            ;;
        suse)
            sudo zypper remove -y wine winetricks 2>/dev/null || true
            ;;
        *)
            echo "Unknown distro. Skipping Wine removal."
            ;;
    esac
    
    echo -e "${GREEN}✅ Wine packages removed.${NC}"
else
    echo "Skipping Wine removal."
fi

# ──────────────────────────────────────────────
# CLEANUP ACTIVATOR FILE
# ──────────────────────────────────────────────
rm -f ~/.multisim32/drive_c/NI.License.Activator.exe 2>/dev/null || true

# ──────────────────────────────────────────────
# DONE
# ──────────────────────────────────────────────
echo
echo "========================================"
echo -e "${GREEN}✅ NI Multisim 14.0 has been uninstalled!${NC}"
echo "========================================"
echo
echo "Residual files (if any) can be found in:"
echo "  - ~/.multisim32 (already removed if existed)"
echo "  - ~/.wine (if you had other Wine prefixes, they remain untouched)"
echo
echo "A reboot is recommended to complete cleanup."
echo

read -rp "Do you want to restart the machine now? [y/N]: " reboot_choice
case "$reboot_choice" in
[Yy] | [Yy][Ee][Ss])
    echo "Restarting system..."
    sudo reboot
    ;;
*)
    echo "Restart skipped. You can reboot later manually."
    ;;
esac
