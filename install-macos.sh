#!/bin/bash
# macOS Multisim 14.0 installer
# Description: Installs Wine via Homebrew, sets up 32-bit prefix, and installs Multisim 14.0 on macOS
# Credits: https://github.com/ghepardoman/NI-Multisim-14-for-Linux
# Activator: https://github.com/AndreaLestingi/NI-Multisim-Crack-1.14

set -e

echo "========================================"
echo "  NI Multisim 14.0 Installer for macOS"
echo "========================================"
echo

# ──────────────────────────────────────────────
# CHECK HOMEBREW
# ──────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "✅ Homebrew detected."

# ──────────────────────────────────────────────
# INSTALL WINE
# ──────────────────────────────────────────────
echo "Installing Wine via Homebrew..."
brew install --cask wine-stable
brew install cabextract

# ──────────────────────────────────────────────
# INSTALL WINETRICKS
# ──────────────────────────────────────────────
if ! command -v winetricks &>/dev/null; then
    echo "Installing winetricks..."
    brew install winetricks
fi

echo "✅ Wine and winetricks installed."

# ──────────────────────────────────────────────
# CREATE 32-BIT WINE PREFIX
# ──────────────────────────────────────────────
export WINEPREFIX="$HOME/.multisim32"
export WINEARCH=win32

echo "Creating 32-bit Wine prefix at $WINEPREFIX..."
winecfg -v winxp 2>/dev/null || true

# ──────────────────────────────────────────────
# INSTALL DEPENDENCIES
# ──────────────────────────────────────────────
echo "Installing core Wine dependencies (corefonts, mdac27, jet40)..."
winetricks -q corefonts mdac27 jet40

# ──────────────────────────────────────────────
# DOWNLOAD MULTISIM
# ──────────────────────────────────────────────
echo "Downloading Multisim 14.0..."
wget -O NI_Circuit_Design_Suite_14_0.zip \
    "https://download.ni.com/support/softlib/Core/Circuit_Design_Suite/14.0/14.0/NI_Circuit_Design_Suite_14_0.zip"

echo "Unzipping Multisim installer..."
unzip -q NI_Circuit_Design_Suite_14_0.zip -d multisim_installer

cd multisim_installer || exit 1

# ──────────────────────────────────────────────
# RUN INSTALLER
# ──────────────────────────────────────────────
echo "Running Multisim installer via Wine..."
(
    WINEPREFIX="$HOME/.multisim32" \
    WINEDEBUG=-all \
    wine cmd /c 'start /wait "" setup.exe'
) >/tmp/multisim-install.log 2>&1 || true

echo "Installer finished."

sleep 5

echo "Stopping Wine..."
wineserver -k || true

# ──────────────────────────────────────────────
# DOWNLOAD AND RUN ACTIVATOR
# ──────────────────────────────────────────────
echo "Downloading NI License Activator..."
ACTIVATOR_URL="https://github.com/AndreaLestingi/NI-Multisim-Crack-1.14/releases/download/activator/NI.License.Activator.exe"
ACTIVATOR_PATH="$HOME/.multisim32/drive_c/NI.License.Activator.exe"

wget -O "$ACTIVATOR_PATH" "$ACTIVATOR_URL"

if [ -f "$ACTIVATOR_PATH" ]; then
    echo "Running NI License Activator under Wine..."
    echo "When the activator window opens, right-click on each product and select 'Activate'"
    echo "Close the activator when done."
    echo
    read -p "Press Enter to open the activator..."
    WINEPREFIX="$HOME/.multisim32" wine "$ACTIVATOR_PATH"
    echo "Activator closed."
else
    echo "ERROR: Failed to download activator. Please check your internet connection."
    exit 1
fi

# ──────────────────────────────────────────────
# CREATE MACOS APPLICATION BUNDLE
# ──────────────────────────────────────────────
echo "Creating macOS application bundle..."

mkdir -p "$HOME/Applications/Multisim.app/Contents/MacOS"
mkdir -p "$HOME/Applications/Multisim.app/Contents/Resources"

cat > "$HOME/Applications/Multisim.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Multisim</string>
    <key>CFBundleIdentifier</key>
    <string>com.nationalinstruments.multisim</string>
    <key>CFBundleName</key>
    <string>Multisim</string>
    <key>CFBundleVersion</key>
    <string>14.0</string>
    <key>CFBundleShortVersionString</key>
    <string>14.0</string>
</dict>
</plist>
EOF

cat > "$HOME/Applications/Multisim.app/Contents/MacOS/Multisim" << 'EOF'
#!/bin/bash
export WINEPREFIX="$HOME/.multisim32"
export WINEARCH=win32
wine "$HOME/.multisim32/drive_c/Program Files/National Instruments/Circuit Design Suite 14.0/Multisim.exe"
EOF

chmod +x "$HOME/Applications/Multisim.app/Contents/MacOS/Multisim"

echo "✅ Application bundle created at ~/Applications/Multisim.app"

# ──────────────────────────────────────────────
# CLEANUP
# ──────────────────────────────────────────────
echo "Cleaning up installation files..."
cd ..
rm -rf multisim_installer NI_Circuit_Design_Suite_14_0.zip

echo
echo "======================================="
echo "✅ Multisim 14.0 installation complete!"
echo "======================================="
echo
echo "You can launch Multisim from:"
echo "  - ~/Applications/Multisim.app"
echo "  - Or run manually: WINEPREFIX=\"$HOME/.multisim32\" wine \"$HOME/.multisim32/drive_c/Program Files/National Instruments/Circuit Design Suite 14.0/Multisim.exe\""
echo
echo "Note: The first launch may take a few seconds."
