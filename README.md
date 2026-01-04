# Hyprland Show Desktop

A simple script for [Hyprland](https://hyprland.org/) that provides a "Show Desktop" functionality, similar to what you'd find in traditional desktop environments.

## Features

- ✅ Toggle show/hide all windows on the current workspace
- ✅ State is remembered per workspace (each workspace has its own desktop state)
- ✅ Works with any number of windows
- ✅ Lightweight and fast
- ✅ No dependencies beyond `jq` (which comes with most Linux distributions)
- ✅ **Two versions available**: Simple and Advanced (choose during installation)

## Version Comparison

### Simple Version (Default)
- **Fast and lightweight** - Minimal overhead
- **Floating windows**: Preserves exact position & size ✅
- **Tiled windows**: Re-tiles according to workspace layout (position not preserved)
- **Best for**: Most users who want quick desktop access

### Advanced Version
- **Preserves exact positions and sizes** for ALL windows
- **Floating windows**: Exact position & size preserved ✅
- **Tiled windows**: Position & size preserved (may need layout adjustment)
- **Slightly slower**: More complex state management
- **Best for**: Users who need exact window restoration, especially with custom layouts

## Requirements

- [Hyprland](https://hyprland.org/) window manager
- `jq` - JSON processor (usually pre-installed or available in your distro's repos)
- `hyprctl` - Comes with Hyprland

## Installation

### Method 1: Installation Script (Recommended)

1. Clone or download this repository:
```bash
git clone https://github.com/JayeshVegda/HyprShowDesktop.git
cd HyprShowDesktop
```

2. Run the installation script:
```bash
./install.sh
```

3. Choose which version to install:
   - **Option 1**: Simple version (default) - Fast, floating windows preserve position/size
   - **Option 2**: Advanced version - Preserves exact positions/sizes for all windows

4. Follow the on-screen instructions to add the keybind and workspace rule to your config

### Method 2: Manual Installation

1. Clone or download this repository:
```bash
git clone https://github.com/JayeshVegda/HyprShowDesktop.git
cd HyprShowDesktop
```

2. Choose which script to copy:
   - **Simple version**: `show-desktop.sh`
   - **Advanced version**: `show-desktop-advanced.sh`

3. Copy the chosen script to your Hyprland config directory:
```bash
mkdir -p ~/.config/hypr/hyprland-show-desktop
cp show-desktop.sh ~/.config/hypr/hyprland-show-desktop/  # or show-desktop-advanced.sh
chmod +x ~/.config/hypr/hyprland-show-desktop/show-desktop.sh
```

4. Add the keybind to your `hyprland.conf`:
```ini
# Show Desktop
bind = $mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh
```

5. Add workspace rule for the special workspace (add to your config, e.g., in `animations.conf` or `general.conf`):
```ini
# Special workspace for show desktop functionality
workspace = special:desktop, gapsout:0, gapsin:0, bordersize:0
```

## Configuration

### Keybind

You can bind the script to any key combination you prefer. Common options:

```ini
# Default: Super + D
bind = $mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh

# Alternative: Super + Shift + D
bind = $mainMod SHIFT, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh

# Or use a function key
bind = , F11, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh
```

### Workspace Rule

The script uses a special workspace named `desktop` to store hidden windows. You can customize this workspace's appearance:

```ini
# Minimal (no gaps, no borders)
workspace = special:desktop, gapsout:0, gapsin:0, bordersize:0

# Or with your preferred styling
workspace = special:desktop, gapsout:10, gapsin:5, bordersize:2
```

## Usage

1. Press your configured keybind (default: `Super + D`)
2. All windows on the current workspace will be hidden
3. Press the keybind again to restore all windows
4. Each workspace maintains its own show desktop state independently

## How It Works

The script:
1. Detects the current workspace
2. When hiding: Moves all windows to a special workspace (`special:desktop`) and stores their addresses
3. When showing: Restores windows from the special workspace back to their original workspace using stored addresses
4. Uses `XDG_RUNTIME_DIR` for temporary state files (falls back to `/tmp` if not set)

## FAQ

### Does it maintain exact position and size of all windows?

**Simple Version:**
- ✅ **Floating windows**: Yes, exact position and size are preserved
- ⚠️ **Tiled windows**: Position is not preserved - windows are re-tiled according to the workspace layout

**Advanced Version:**
- ✅ **Floating windows**: Yes, exact position and size are preserved
- ✅ **Tiled windows**: Position and size are preserved (exact pixel positions restored)

### Which version should I choose?

- **Choose Simple version** if you want fast, lightweight functionality and don't need exact tiled window positions
- **Choose Advanced version** if you need exact window positions/sizes preserved for all windows, especially with custom layouts

### Can I switch versions after installation?

Yes! Simply run `./install.sh` again and choose a different version, or manually copy the desired script file.

## Troubleshooting

### Script doesn't work

1. **Check if `jq` is installed:**
   ```bash
   which jq
   ```
   If not installed, install it:
   ```bash
   # Arch/Manjaro
   sudo pacman -S jq
   
   # Debian/Ubuntu
   sudo apt install jq
   
   # Fedora
   sudo dnf install jq
   ```

2. **Check script permissions:**
   ```bash
   chmod +x ~/.config/hypr/hyprland-show-desktop/show-desktop.sh
   ```

3. **Test the script manually:**
   ```bash
   ~/.config/hypr/hyprland-show-desktop/show-desktop.sh
   ```

4. **Check Hyprland logs:**
   ```bash
   hyprctl logs
   ```

### Windows don't restore properly

- Make sure the workspace rule for `special:desktop` is in your config
- Try reloading your config: `hyprctl reload`
- Check if the state file exists: `ls -la $XDG_RUNTIME_DIR/hyprland-show-desktop-*`

## Customization

### Change Special Workspace Name

If you want to use a different special workspace name:

1. Edit `show-desktop.sh` and replace `special:desktop` with your preferred name (e.g., `special:hidden`)
2. Update the workspace rule in your config accordingly

### Add Notification

You can add a notification when toggling:

```ini
bind = $mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh && hyprctl notify 1 2000 "rgb(89b4fa)" "Desktop toggled"
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Based on the [Hyprland Wiki's Show Desktop example](https://wiki.hyprland.org/Configuring/Uncommon-tips-&-tricks/#show-desktop)
- Inspired by traditional desktop environment show desktop functionality

## Related Projects

- [Hyprland](https://github.com/hyprwm/Hyprland) - The window manager this script is designed for
