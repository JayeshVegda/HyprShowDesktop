#!/usr/bin/env bash
#
# Installation script for Hyprland Show Desktop
#

set -e

# Error handling function
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Color output functions (if terminal supports it)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    GREEN=''
    YELLOW=''
    RED=''
    CYAN=''
    BOLD=''
    NC=''
fi

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

echo -e "${BOLD}Installing Hyprland Show Desktop...${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || pwd)"

# Check if script directory is accessible
if [ ! -d "$SCRIPT_DIR" ]; then
    error_exit "Cannot determine script directory."
fi

# Check if scripts exist
if [ ! -f "$SCRIPT_DIR/show-desktop.sh" ]; then
    error_exit "show-desktop.sh not found in $SCRIPT_DIR"
fi

if [ ! -f "$SCRIPT_DIR/show-desktop-advanced.sh" ]; then
    error_exit "show-desktop-advanced.sh not found in $SCRIPT_DIR"
fi

# Check if scripts are readable
if [ ! -r "$SCRIPT_DIR/show-desktop.sh" ] || [ ! -r "$SCRIPT_DIR/show-desktop-advanced.sh" ]; then
    error_exit "Cannot read script files. Check file permissions."
fi

# Set installation directory
INSTALL_DIR="$HOME/.config/hypr/hyprland-show-desktop"

# Check if HOME is set
if [ -z "$HOME" ]; then
    error_exit "HOME environment variable is not set."
fi

# Check if .config directory exists or can be created
CONFIG_DIR="$HOME/.config"
if [ ! -d "$CONFIG_DIR" ]; then
    if ! mkdir -p "$CONFIG_DIR" 2>/dev/null; then
        error_exit "Cannot create $CONFIG_DIR directory. Check permissions."
    fi
fi

# Check if hypr directory exists or can be created
HYPR_DIR="$HOME/.config/hypr"
if [ ! -d "$HYPR_DIR" ]; then
    if ! mkdir -p "$HYPR_DIR" 2>/dev/null; then
        error_exit "Cannot create $HYPR_DIR directory. Check permissions."
    fi
fi

# Create installation directory
if ! mkdir -p "$INSTALL_DIR" 2>/dev/null; then
    error_exit "Cannot create installation directory: $INSTALL_DIR"
fi

# Check if installation directory is writable
if [ ! -w "$INSTALL_DIR" ]; then
    error_exit "Installation directory is not writable: $INSTALL_DIR"
fi

# Ask user which version to install
echo -e "${BOLD}Which version would you like to install?${NC}"
echo ""
echo "  ${CYAN}1)${NC} Simple version (default)"
echo "     - Fast and lightweight"
echo "     - Floating windows: preserves position & size"
echo "     - Tiled windows: re-tiles according to workspace layout"
echo ""
echo "  ${CYAN}2)${NC} Advanced version"
echo "     - Preserves exact positions and sizes for ALL windows"
echo "     - Floating windows: exact position & size preserved"
echo "     - Tiled windows: position & size preserved (may need layout adjustment)"
echo "     - More complex, slightly slower"
echo ""
echo -n "Enter choice [1-2] (default: 1): "
read -r VERSION_CHOICE

# Default to simple if empty
VERSION_CHOICE=${VERSION_CHOICE:-1}

case "$VERSION_CHOICE" in
    1)
        SCRIPT_NAME="show-desktop.sh"
        VERSION_TYPE="Simple"
        ;;
    2)
        SCRIPT_NAME="show-desktop-advanced.sh"
        VERSION_TYPE="Advanced"
        ;;
    *)
        warning "Invalid choice. Installing simple version by default."
        SCRIPT_NAME="show-desktop.sh"
        VERSION_TYPE="Simple"
        ;;
esac

echo ""
info "Installing ${VERSION_TYPE} version..."

# Copy selected script
if ! cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/show-desktop.sh" 2>/dev/null; then
    error_exit "Failed to copy $SCRIPT_NAME to $INSTALL_DIR"
fi

# Make script executable
if ! chmod +x "$INSTALL_DIR/show-desktop.sh" 2>/dev/null; then
    error_exit "Failed to make show-desktop.sh executable."
fi

# Verify the file was copied and is executable
if [ ! -f "$INSTALL_DIR/show-desktop.sh" ]; then
    error_exit "Verification failed: show-desktop.sh not found in $INSTALL_DIR"
fi

if [ ! -x "$INSTALL_DIR/show-desktop.sh" ]; then
    error_exit "Verification failed: show-desktop.sh is not executable"
fi

success "Script ($VERSION_TYPE version) installed to $INSTALL_DIR"
echo ""

# Check dependencies
echo "Checking dependencies..."

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    warning "jq is not installed. The script requires jq to work."
    echo "  Install it with:"
    echo "    Arch/Manjaro: sudo pacman -S jq"
    echo "    Debian/Ubuntu: sudo apt install jq"
    echo "    Fedora/RHEL: sudo dnf install jq"
    echo "    openSUSE: sudo zypper install jq"
    echo "    macOS: brew install jq"
    MISSING_DEPS=1
else
    success "jq is installed ($(jq --version 2>/dev/null || echo 'version unknown'))"
fi

# Check if hyprctl is available
if ! command -v hyprctl >/dev/null 2>&1; then
    warning "hyprctl not found. Make sure Hyprland is installed and in your PATH."
    MISSING_DEPS=1
else
    # Try to get Hyprland version
    HYPR_VERSION=$(hyprctl version 2>/dev/null | head -n1 || echo "unknown")
    success "hyprctl is available (Hyprland $HYPR_VERSION)"
fi

# Check if Hyprland is running (optional check)
if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl version >/dev/null 2>&1; then
        success "Hyprland is running"
    else
        warning "Hyprland does not appear to be running (this is okay if installing before first run)"
    fi
fi

echo ""

# Installation summary
if [ -z "${MISSING_DEPS:-}" ]; then
    success "All dependencies are installed!"
else
    warning "Some dependencies are missing. Please install them before using the script."
fi

echo ""
echo -e "${BOLD}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Add this keybind to your hyprland.conf (or modules/bind.conf):"
echo "   ${GREEN}bind = \$mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh${NC}"
echo ""
echo "2. Add this workspace rule to your config (e.g., animations.conf or general.conf):"
echo "   ${GREEN}workspace = special:desktop, gapsout:0, gapsin:0, bordersize:0${NC}"
echo ""
echo "3. Reload your config:"
echo "   ${GREEN}hyprctl reload${NC}"
echo ""
echo "4. Test it by pressing your configured keybind (default: Super + D)"
echo ""

if [ "$VERSION_TYPE" = "Advanced" ]; then
    info "Note: The Advanced version preserves exact window positions and sizes."
    info "      For best results, ensure your workspace layout settings are consistent."
fi

echo ""
