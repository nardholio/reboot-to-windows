#!/bin/sh
# /usr/bin/reboot-to-windows
# Reboot into Windows by setting the next boot entry via efibootmgr
# Handles several desktop environments with their native reboot/shutdown dialog
# Relies on a Polkit rule allowing wheel group to pkexec this exact script without password

set -e

# ------------------------------------------------------------------
# Helper: send notification and exit with error
# ------------------------------------------------------------------
fail() {
    if [ -n "${DISPLAY:-}" ] && command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Reboot to Windows" "Reboot Unsuccessful" "$1"
    else
        printf 'Reboot to Windows: ERROR: %s\n' "$1" >&2
    fi
    exit 1
}

# ------------------------------------------------------------------
# Elevated mode: running as root via pkexec --elevated
# ------------------------------------------------------------------
if [ "$1" = "--elevated" ]; then
    if [ "$(id -u)" != "0" ]; then
        fail "Elevated mode must be run as root."
    fi
    shift
    WINDOWS_BOOT="$1"
    NEEDS_SET_BOOT="$2"
    REBOOT_CMD="$3"
    NEEDS_PKEXEC="$4"

    if [ "$NEEDS_SET_BOOT" = "1" ]; then
        efibootmgr -n "$WINDOWS_BOOT" >/dev/null
    fi

    if [ "$NEEDS_PKEXEC" = "1" ]; then
        exec systemctl reboot
    fi

    exit 0
fi

# ------------------------------------------------------------------
# Direct root invocation fallback (e.g. sudo reboot-to-windows)
# ------------------------------------------------------------------
if [ "$(id -u)" = "0" ]; then
    # No DE session info available → force privileged reboot
    WINDOWS_BOOT=$(efibootmgr -v | grep -i Windows | grep -Eo 'Boot[0-9]{4}' | grep -Eo '[0-9]{4}' | head -n1)
    [ -z "$WINDOWS_BOOT" ] && fail "The Windows boot option was not found on the system."

    CURRENT_NEXT=$(efibootmgr | grep -i 'BootNext' | grep -Eo '[0-9]{4}' || echo "")
    [ "$CURRENT_NEXT" != "$WINDOWS_BOOT" ] && efibootmgr -n "$WINDOWS_BOOT" >/dev/null

    exec systemctl reboot
fi

# ------------------------------------------------------------------
# Normal non-root execution
# ------------------------------------------------------------------

# Find Windows boot entry
WINDOWS_BOOT=$(efibootmgr -v | grep -i Windows | grep -Eo 'Boot[0-9]{4}' | grep -Eo '[0-9]{4}' | head -n1)
[ -z "$WINDOWS_BOOT" ] && fail "The Windows boot option was not found on the system."

# Check if we need to set BootNext
CURRENT_NEXT=$(efibootmgr | grep -i 'BootNext' | grep -Eo '[0-9]{4}' || echo "")
NEEDS_SET_BOOT="0"
[ "$CURRENT_NEXT" != "$WINDOWS_BOOT" ] && NEEDS_SET_BOOT="1"

# ------------------------------------------------------------------
# Desktop Environment detection
# Each entry sets:
#   REBOOT_CMD   → command that shows the native reboot dialog
#   NEEDS_PKEXEC → 1 if the reboot itself requires root, 0 if the DE handles it
# ------------------------------------------------------------------
REBOOT_CMD="systemctl reboot"
NEEDS_PKEXEC="1"

case "${DESKTOP_SESSION:-unknown}" in
    gnome|gnome-classic|gnome-xorg)
        REBOOT_CMD="gnome-session-quit --reboot"
        NEEDS_PKEXEC="0"
        ;;
    plasma|kde)
        if command -v qdbus >/dev/null 2>&1; then
            REBOOT_CMD="qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot"
            NEEDS_PKEXEC="0"
        fi
        ;;
    xfce|xfce4)
        REBOOT_CMD="xfce4-session-logout --reboot"
        NEEDS_PKEXEC="0"
        ;;
    mate)
        REBOOT_CMD="mate-session-save --shutdown-dialog"
        NEEDS_PKEXEC="0"
        ;;
    cinnamon|cinnamon-wayland)
        REBOOT_CMD="cinnamon-session-quit --reboot"
        NEEDS_PKEXEC="0"
        ;;
    lxqt)
        REBOOT_CMD="lxqt-leave --reboot"
        NEEDS_PKEXEC="0"
        ;;
    budgie)
        REBOOT_CMD="budgie-session --reboot"
        NEEDS_PKEXEC="0"
        ;;
esac

# ------------------------------------------------------------------
# Elevation handling
# ------------------------------------------------------------------
if [ "$NEEDS_SET_BOOT" = "1" ] || [ "$NEEDS_PKEXEC" = "1" ]; then
    # Try pkexec first (standard way)
    if command -v pkexec >/dev/null 2>&1; then
        if [ "$NEEDS_PKEXEC" = "1" ]; then
            exec pkexec "$0" --elevated "$WINDOWS_BOOT" "$NEEDS_SET_BOOT" "$REBOOT_CMD" "$NEEDS_PKEXEC"
        else
            pkexec "$0" --elevated "$WINDOWS_BOOT" "$NEEDS_SET_BOOT" "$REBOOT_CMD" "$NEEDS_PKEXEC" || \
                fail "Failed to set next boot entry (pkexec denied)."
        fi
    else
        # pkexec not available – fall back to requiring manual sudo
        fail "This operation requires root privileges.\nPlease run: sudo $0"
    fi
fi

# ------------------------------------------------------------------
# Show the desktop environment's native reboot dialog
# ------------------------------------------------------------------
eval "$REBOOT_CMD"
