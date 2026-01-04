#!/usr/bin/env sh
#
# Hyprland Show Desktop Script
# Toggles showing/hiding all windows on the current workspace
# State is remembered per workspace
#
# Usage: ./show-desktop.sh
# Bind to a key in hyprland.conf: bind = $mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh

set -e

# Error handling function
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Check if hyprctl is available
if ! command -v hyprctl >/dev/null 2>&1; then
    error_exit "hyprctl not found. Make sure Hyprland is installed and running."
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    error_exit "jq is not installed. Please install it: sudo pacman -S jq (Arch) or sudo apt install jq (Debian/Ubuntu)"
fi

# Check if Hyprland is running
if ! hyprctl version >/dev/null 2>&1; then
    error_exit "Hyprland is not running or hyprctl cannot connect."
fi

# Set up temporary file directory
TMP_DIR="${XDG_RUNTIME_DIR:-/tmp}"
if [ ! -d "$TMP_DIR" ] || [ ! -w "$TMP_DIR" ]; then
    error_exit "Cannot write to temporary directory: $TMP_DIR"
fi

TMP_FILE="$TMP_DIR/hyprland-show-desktop"

# Get current workspace name with error handling
MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$MONITORS_JSON" ]; then
    error_exit "Failed to get monitor information from hyprctl."
fi

CURRENT_WORKSPACE=$(echo "$MONITORS_JSON" | jq -r '.[] | .activeWorkspace | .name' 2>/dev/null | head -n1)

if [ -z "$CURRENT_WORKSPACE" ] || [ "$CURRENT_WORKSPACE" = "null" ]; then
    error_exit "Could not determine current workspace. Make sure you have at least one monitor active."
fi

WORKSPACE_STATE_FILE="$TMP_FILE-$CURRENT_WORKSPACE"

# Check if windows are hidden (file exists and has content)
if [ -s "$WORKSPACE_STATE_FILE" ]; then
    # Restore windows: read addresses from file and move them back
    if [ ! -r "$WORKSPACE_STATE_FILE" ]; then
        error_exit "Cannot read state file: $WORKSPACE_STATE_FILE"
    fi
    
    # Process addresses and build commands
    CMDS=""
    RESTORED_COUNT=0
    
    while IFS= read -r address || [ -n "$address" ]; do
        address=$(echo "$address" | tr -d '[:space:]')
        if [ -n "$address" ] && [ "$address" != "" ]; then
            CMDS="${CMDS}dispatch movetoworkspacesilent name:$CURRENT_WORKSPACE,address:$address;"
            RESTORED_COUNT=$((RESTORED_COUNT + 1))
        fi
    done < "$WORKSPACE_STATE_FILE"
    
    if [ -n "$CMDS" ] && [ "$RESTORED_COUNT" -gt 0 ]; then
        # Execute restore commands
        if ! hyprctl --batch "$CMDS" >/dev/null 2>&1; then
            # If restore fails, clean up state file to prevent stuck state
            rm -f "$WORKSPACE_STATE_FILE"
            error_exit "Failed to restore windows. State file has been cleared."
        fi
    fi
    
    # Clean up state file after successful restore
    if ! rm -f "$WORKSPACE_STATE_FILE"; then
        echo "Warning: Could not remove state file: $WORKSPACE_STATE_FILE" >&2
    fi
else
    # Hide windows: get all windows on current workspace and move to special workspace
    CLIENTS_JSON=$(hyprctl clients -j 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$CLIENTS_JSON" ]; then
        error_exit "Failed to get client information from hyprctl."
    fi
    
    HIDDEN_WINDOWS=$(echo "$CLIENTS_JSON" | jq -r --arg CW "$CURRENT_WORKSPACE" '.[] | select(.workspace.name == $CW) | .address' 2>/dev/null)
    
    if [ -z "$HIDDEN_WINDOWS" ]; then
        # No windows to hide - this is not an error, just exit silently
        exit 0
    fi
    
    # Store addresses for restoration
    TMP_ADDRESS=""
    CMDS=""
    HIDDEN_COUNT=0
    
    while IFS= read -r address || [ -n "$address" ]; do
        address=$(echo "$address" | tr -d '[:space:]')
        if [ -n "$address" ] && [ "$address" != "" ] && [ "$address" != "null" ]; then
            TMP_ADDRESS="${TMP_ADDRESS}${address}\n"
            CMDS="${CMDS}dispatch movetoworkspacesilent special:desktop,address:$address;"
            HIDDEN_COUNT=$((HIDDEN_COUNT + 1))
        fi
    done <<EOF
$HIDDEN_WINDOWS
EOF
    
    if [ -n "$CMDS" ] && [ "$HIDDEN_COUNT" -gt 0 ]; then
        # Execute hide commands
        if ! hyprctl --batch "$CMDS" >/dev/null 2>&1; then
            error_exit "Failed to hide windows. Make sure the special workspace 'desktop' is configured in your hyprland.conf"
        fi
        
        # Save state for restoration
        TMP_ADDRESS_CLEAN=$(echo -e "$TMP_ADDRESS" | sed -e '/^$/d')
        if [ -n "$TMP_ADDRESS_CLEAN" ]; then
            if ! echo -e "$TMP_ADDRESS_CLEAN" > "$WORKSPACE_STATE_FILE" 2>/dev/null; then
                # If we can't save state, try to restore windows to prevent data loss
                RESTORE_CMDS=""
                while IFS= read -r addr || [ -n "$addr" ]; do
                    addr=$(echo "$addr" | tr -d '[:space:]')
                    if [ -n "$addr" ]; then
                        RESTORE_CMDS="${RESTORE_CMDS}dispatch movetoworkspacesilent name:$CURRENT_WORKSPACE,address:$addr;"
                    fi
                done <<EOF
$HIDDEN_WINDOWS
EOF
                hyprctl --batch "$RESTORE_CMDS" >/dev/null 2>&1 || true
                error_exit "Failed to save state file. Windows were not hidden to prevent data loss."
            fi
        fi
    fi
fi

exit 0
