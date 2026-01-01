#!/bin/sh
set -e # Halts the program if error occurs (i.e., not getting sudo permission)

# Gets list of boot options.
# Then searches for line containing 'Windows' in these options (case
# insensitive).
# Gets the 'Boot____*' value of this line.
# Extracts the 4-digit number from this value.
# If unsuccessful, the variable is set to empty.
WINDOWS_BOOT=$(efibootmgr -v | grep -i Windows | grep -Eo 'Boot[0-9]{4}' | grep -Eo '[0-9]{4}' | head -n1)

if [ -z "$WINDOWS_BOOT" ]; then # If Windows was not found:
    # Display notification.
    notify-send -a Windows "Reboot Unsuccessful" \
        "The Windows boot option was not found on the system."
    exit 1 # Exit the program with code 1.
fi

# Get current BootNext
CURRENT_NEXT=$(efibootmgr | grep -i 'BootNext' | grep -Eo '[0-9]{4}' || echo "")

NEEDS_SET_BOOT=0
if [ "$CURRENT_NEXT" != "$WINDOWS_BOOT" ]; then
    NEEDS_SET_BOOT=1
fi

# Determine DE-specific reboot command and whether it needs pkexec
case "$DESKTOP_SESSION" in
    gnome) # If user running GNOME:
        REBOOT_CMD="gnome-session-quit --reboot"
        NEEDS_PKEXEC=0
        ;;
    plasma) # If user running KDE Plasma:
        # Check for 'qdbus' command. If empty, set to empty.
        QDBUS=$(which qdbus 2>/dev/null || echo "")
        if [ -n "$QDBUS" ]; then
            # Show KDE Plasma reboot prompt
            REBOOT_CMD="$QDBUS org.kde.LogoutPrompt /LogoutPrompt promptReboot"
            NEEDS_PKEXEC=0
        else
            REBOOT_CMD="systemctl reboot"
            NEEDS_PKEXEC=1
        fi
        ;;
    cinnamon)
        REBOOT_CMD="cinnamon-session-quit --reboot"
        NEEDS_PKEXEC=0
        ;;
    *) # If running another desktop environment:
        REBOOT_CMD="systemctl reboot"
        NEEDS_PKEXEC=1
        ;;
esac

# Always run privileged actions (if any) in one pkexec call
if [ "$NEEDS_SET_BOOT" = "1" ] || [ "$NEEDS_PKEXEC" = "1" ]; then
    CMD=""
    if [ "$NEEDS_SET_BOOT" = "1" ]; then
        CMD="efibootmgr -n $WINDOWS_BOOT"
    fi
    if [ "$NEEDS_PKEXEC" = "1" ]; then
        if [ -n "$CMD" ]; then
            CMD="$CMD && systemctl reboot"
        else
            CMD="systemctl reboot"
        fi
    fi
    pkexec sh -c "$CMD"
fi

# If we reach here, either:
# - No privileged action was needed, or
# - We just set BootNext but the DE can handle the reboot prompt itself
if [ "$NEEDS_PKEXEC" = "0" ]; then
    eval "$REBOOT_CMD"
fi
