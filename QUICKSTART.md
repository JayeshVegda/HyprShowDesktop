# Quick Start Guide

Get up and running with Hyprland Show Desktop in 3 steps!

## Step 1: Install

### Option A: Using the install script
```bash
git clone https://github.com/JayeshVegda/HyprShowDesktop.git
cd HyprShowDesktop
./install.sh
```

### Option B: Manual installation
```bash
mkdir -p ~/.config/hypr/hyprland-show-desktop
cp show-desktop.sh ~/.config/hypr/hyprland-show-desktop/
chmod +x ~/.config/hypr/hyprland-show-desktop/show-desktop.sh
```

## Step 2: Add to Config

Add this to your `hyprland.conf` (or `modules/bind.conf`):

```ini
bind = $mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh
```

Add this workspace rule (to `animations.conf` or `general.conf`):

```ini
workspace = special:desktop, gapsout:0, gapsin:0, bordersize:0
```

## Step 3: Reload

```bash
hyprctl reload
```

## Done! 🎉

Press `Super + D` to toggle show desktop!

For more details, see the [full README](README.md).
