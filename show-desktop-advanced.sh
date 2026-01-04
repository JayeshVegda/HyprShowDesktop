#!/usr/bin/env sh
#
# Hyprland Show Desktop Script (Advanced Version)
# Toggles showing/hiding all windows on the current workspace
# State is remembered per workspace
# ADVANCED: Preserves exact window positions, sizes, and floating states
#
# Usage: ./show-desktop-advanced.sh
# Bind to a key in hyprland.conf: bind = $mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop-advanced.sh

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

TMP_FILE="$TMP_DIR/hyprland-show-desktop-advanced"

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
    # Restore windows: read window data from JSON file and restore
    if [ ! -r "$WORKSPACE_STATE_FILE" ]; then
        error_exit "Cannot read state file: $WORKSPACE_STATE_FILE"
    fi
    
    # Read JSON state file
    WINDOW_STATE_JSON=$(cat "$WORKSPACE_STATE_FILE" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$WINDOW_STATE_JSON" ]; then
        error_exit "Failed to read state file: $WORKSPACE_STATE_FILE"
    fi
    
    # Validate JSON
    if ! echo "$WINDOW_STATE_JSON" | jq empty 2>/dev/null; then
        error_exit "Invalid JSON in state file: $WORKSPACE_STATE_FILE"
    fi
    
    # Create temp file for commands
    TEMP_CMDS_FILE="$TMP_DIR/hyprland-restore-cmds-$$"
    rm -f "$TEMP_CMDS_FILE"
    
    # Process each window in the state file
    WINDOW_COUNT=$(echo "$WINDOW_STATE_JSON" | jq '. | length' 2>/dev/null)
    if [ -z "$WINDOW_COUNT" ] || [ "$WINDOW_COUNT" = "0" ] || [ "$WINDOW_COUNT" = "null" ]; then
        rm -f "$WORKSPACE_STATE_FILE"
        exit 0
    fi
    
    # Build restore commands for each window
    echo "$WINDOW_STATE_JSON" | jq -c '.[]' 2>/dev/null | while IFS= read -r window_data || [ -n "$window_data" ]; do
        if [ -z "$window_data" ] || [ "$window_data" = "null" ]; then
            continue
        fi
        
        # Extract window properties
        address=$(echo "$window_data" | jq -r '.address' 2>/dev/null)
        is_floating=$(echo "$window_data" | jq -r '.floating' 2>/dev/null)
        at_x=$(echo "$window_data" | jq -r '.at[0]' 2>/dev/null)
        at_y=$(echo "$window_data" | jq -r '.at[1]' 2>/dev/null)
        size_w=$(echo "$window_data" | jq -r '.size[0]' 2>/dev/null)
        size_h=$(echo "$window_data" | jq -r '.size[1]' 2>/dev/null)
        
        if [ -z "$address" ] || [ "$address" = "null" ] || [ "$address" = "" ]; then
            continue
        fi
        
        # Append commands to temp file
        echo "dispatch movetoworkspacesilent name:$CURRENT_WORKSPACE,address:$address;" >> "$TEMP_CMDS_FILE"
        
        # If floating, restore position and size
        if [ "$is_floating" = "true" ] || [ "$is_floating" = "1" ]; then
            echo "dispatch setfloating active,address:$address;" >> "$TEMP_CMDS_FILE"
            
            # Restore position and size (only if valid numbers)
            if [ -n "$at_x" ] && [ "$at_x" != "null" ] && [ -n "$at_y" ] && [ "$at_y" != "null" ] && \
               [ -n "$size_w" ] && [ "$size_w" != "null" ] && [ -n "$size_h" ] && [ "$size_h" != "null" ]; then
                # Validate they are numbers (including negative for position)
                if echo "$at_x" | grep -qE '^-?[0-9]+$' && echo "$at_y" | grep -qE '^-?[0-9]+$' && \
                   echo "$size_w" | grep -qE '^[0-9]+$' && echo "$size_h" | grep -qE '^[0-9]+$'; then
                    echo "dispatch movewindowpixel exact $at_x $at_y,address:$address;" >> "$TEMP_CMDS_FILE"
                    echo "dispatch resizewindowpixel exact $size_w $size_h,address:$address;" >> "$TEMP_CMDS_FILE"
                fi
            fi
        else
            # Ensure window is tiled (not floating)
            echo "dispatch settiled active,address:$address;" >> "$TEMP_CMDS_FILE"
        fi
    done
    
    # Execute all restore commands at once
    if [ -f "$TEMP_CMDS_FILE" ] && [ -s "$TEMP_CMDS_FILE" ]; then
        CMDS=$(cat "$TEMP_CMDS_FILE" | tr '\n' ' ')
        if [ -n "$CMDS" ]; then
            if ! hyprctl --batch "$CMDS" >/dev/null 2>&1; then
                rm -f "$TEMP_CMDS_FILE"
                rm -f "$WORKSPACE_STATE_FILE"
                error_exit "Failed to restore windows. State file has been cleared."
            fi
        fi
        rm -f "$TEMP_CMDS_FILE"
    fi
    
    # Clean up state file after successful restore
    if ! rm -f "$WORKSPACE_STATE_FILE"; then
        echo "Warning: Could not remove state file: $WORKSPACE_STATE_FILE" >&2
    fi
else
    # Hide windows: get all windows on current workspace and save their state
    CLIENTS_JSON=$(hyprctl clients -j 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$CLIENTS_JSON" ]; then
        error_exit "Failed to get client information from hyprctl."
    fi
    
    # Get windows on current workspace with their properties
    WINDOWS_ON_WORKSPACE=$(echo "$CLIENTS_JSON" | jq --arg CW "$CURRENT_WORKSPACE" '.[] | select(.workspace.name == $CW) | {
        address: .address,
        floating: .floating,
        at: .at,
        size: .size
    }' 2>/dev/null)
    
    if [ -z "$WINDOWS_ON_WORKSPACE" ] || [ "$WINDOWS_ON_WORKSPACE" = "[]" ]; then
        # No windows to hide
        exit 0
    fi
    
    # Convert to array format
    WINDOWS_ARRAY=$(echo "$WINDOWS_ON_WORKSPACE" | jq -s '.' 2>/dev/null)
    
    if [ -z "$WINDOWS_ARRAY" ] || [ "$WINDOWS_ARRAY" = "null" ]; then
        error_exit "Failed to process window data."
    fi
    
    # Extract addresses for moving to special workspace
    WINDOW_ADDRESSES=$(echo "$WINDOWS_ARRAY" | jq -r '.[] | .address' 2>/dev/null)
    
    if [ -z "$WINDOW_ADDRESSES" ]; then
        error_exit "No valid window addresses found."
    fi
    
    # Build move commands
    CMDS=""
    HIDDEN_COUNT=0
    
    while IFS= read -r address || [ -n "$address" ]; do
        address=$(echo "$address" | tr -d '[:space:]')
        if [ -n "$address" ] && [ "$address" != "" ] && [ "$address" != "null" ]; then
            CMDS="${CMDS}dispatch movetoworkspacesilent special:desktop,address:$address;"
            HIDDEN_COUNT=$((HIDDEN_COUNT + 1))
        fi
    done <<EOF
$WINDOW_ADDRESSES
EOF
    
    if [ -n "$CMDS" ] && [ "$HIDDEN_COUNT" -gt 0 ]; then
        # Execute hide commands
        if ! hyprctl --batch "$CMDS" >/dev/null 2>&1; then
            error_exit "Failed to hide windows. Make sure the special workspace 'desktop' is configured in your hyprland.conf"
        fi
        
        # Save state for restoration (save as JSON)
        if ! echo "$WINDOWS_ARRAY" > "$WORKSPACE_STATE_FILE" 2>/dev/null; then
            # If we can't save state, try to restore windows
            RESTORE_CMDS=""
            while IFS= read -r addr || [ -n "$addr" ]; do
                addr=$(echo "$addr" | tr -d '[:space:]')
                if [ -n "$addr" ]; then
                    RESTORE_CMDS="${RESTORE_CMDS}dispatch movetoworkspacesilent name:$CURRENT_WORKSPACE,address:$addr;"
                fi
            done <<EOF
$WINDOW_ADDRESSES
EOF
            hyprctl --batch "$RESTORE_CMDS" >/dev/null 2>&1 || true
            error_exit "Failed to save state file. Windows were not hidden to prevent data loss."
        fi
    fi
fi

exit 0
