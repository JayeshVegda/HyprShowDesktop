#!/usr/bin/env bash
#
# Installation script for Hyprland Show Desktop
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.config/hypr/hyprland-show-desktop"

echo "Installing Hyprland Show Desktop..."

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy script
cp "$SCRIPT_DIR/show-desktop.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/show-desktop.sh"

echo "✓ Script installed to $INSTALL_DIR"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "⚠ Warning: jq is not installed. The script requires jq to work."
    echo "  Install it with:"
    echo "    Arch/Manjaro: sudo pacman -S jq"
    echo "    Debian/Ubuntu: sudo apt install jq"
    echo "    Fedora: sudo dnf install jq"
else
    echo "✓ jq is installed"
fi

# Check if hyprctl is available
if ! command -v hyprctl &> /dev/null; then
    echo "⚠ Warning: hyprctl not found. Make sure Hyprland is installed."
else
    echo "✓ hyprctl is available"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Add this keybind to your hyprland.conf:"
echo "   bind = \$mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh"
echo ""
echo "2. Add this workspace rule to your config:"
echo "   workspace = special:desktop, gapsout:0, gapsin:0, bordersize:0"
echo ""
echo "3. Reload your config: hyprctl reload"
