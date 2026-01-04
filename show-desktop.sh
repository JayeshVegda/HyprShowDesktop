#!/usr/bin/env sh
#
# Hyprland Show Desktop Script
# Toggles showing/hiding all windows on the current workspace
# State is remembered per workspace
#
# Usage: ./show-desktop.sh
# Bind to a key in hyprland.conf: bind = $mainMod, D, exec, ~/.config/hypr/hyprland-show-desktop/show-desktop.sh

TMP_FILE="${XDG_RUNTIME_DIR:-/tmp}/hyprland-show-desktop"

# Get current workspace name
CURRENT_WORKSPACE=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | .activeWorkspace | .name' | head -n1)

if [ -z "$CURRENT_WORKSPACE" ]; then
    echo "Error: Could not get current workspace" >&2
    exit 1
fi

WORKSPACE_STATE_FILE="$TMP_FILE-$CURRENT_WORKSPACE"

# Check if windows are hidden (file exists and has content)
if [ -s "$WORKSPACE_STATE_FILE" ]; then
    # Restore windows: read addresses from file and move them back
    readarray -d $'\n' -t ADDRESS_ARRAY < "$WORKSPACE_STATE_FILE" 2>/dev/null || true
    
    if [ ${#ADDRESS_ARRAY[@]} -gt 0 ]; then
        CMDS=""
        for address in "${ADDRESS_ARRAY[@]}"
        do
            # Remove any whitespace/newlines
            address=$(echo "$address" | tr -d '[:space:]')
            if [ -n "$address" ]; then
                CMDS="${CMDS}dispatch movetoworkspacesilent name:$CURRENT_WORKSPACE,address:$address;"
            fi
        done
        
        if [ -n "$CMDS" ]; then
            hyprctl --batch "$CMDS" >/dev/null 2>&1
        fi
    fi
    
    # Clean up state file
    rm -f "$WORKSPACE_STATE_FILE"
else
    # Hide windows: get all windows on current workspace and move to special workspace
    HIDDEN_WINDOWS=$(hyprctl clients -j 2>/dev/null | jq -r --arg CW "$CURRENT_WORKSPACE" '.[] | select(.workspace.name == $CW) | .address')
    
    if [ -z "$HIDDEN_WINDOWS" ]; then
        # No windows to hide
        exit 0
    fi
    
    # Store addresses for restoration
    TMP_ADDRESS=""
    CMDS=""
    
    while IFS= read -r address; do
        if [ -n "$address" ]; then
            TMP_ADDRESS="${TMP_ADDRESS}${address}\n"
            CMDS="${CMDS}dispatch movetoworkspacesilent special:desktop,address:$address;"
        fi
    done <<EOF
$HIDDEN_WINDOWS
EOF
    
    if [ -n "$CMDS" ]; then
        hyprctl --batch "$CMDS" >/dev/null 2>&1
        
        # Save state for restoration
        echo -e "$TMP_ADDRESS" | sed -e '/^$/d' > "$WORKSPACE_STATE_FILE"
    fi
fi
