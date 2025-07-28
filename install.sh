#!/bin/sh

if [ $UID != 0 ]; then
    echo "Please run this installer as root."
    exit 1
fi

ICON_LOCATION=/usr/share/pixmaps/reboot-to-windows.svg
EXECUTABLE_LOCATION=/usr/bin/reboot-to-windows
WRAPPER_LOCATION=/usr/lib/reboot-to-windows-pkexec.sh
DESKTOP_FILE_LOCATION=/usr/share/applications/reboot-to-windows.desktop

install -Dm644 icons/reboot-to-windows.svg "$ICON_LOCATION"
install -Dm755 scripts/reboot-to-windows.sh "$EXECUTABLE_LOCATION"
install -Dm755 scripts/reboot-to-windows-pkexec.sh "$WRAPPER_LOCATION"
install -Dm644 reboot-to-windows.desktop "$DESKTOP_FILE_LOCATION"

if [ "$DESKTOP_SESSION" = "plasma" ]; then # If user running KDE Plasma:
    # Check for 'qdbus' command. If empty, set to -1.
    QDBUS=`which qdbus 2>/dev/null || echo -1`
    if [ "$QDBUS" = "-1" ]; then # If qdbus command not found:
        echo "Install the 'qt' or 'qt5-tools' or similar package from your package manager to provide support for KDE's reboot prompt."
    fi
fi

echo "**********************************************************************"
echo "To allow wheel users to reboot to Windows without a password, copy the polkit files:"
echo "  sudo cp ./polkit/wartybix.reboot-to-windows.policy /usr/share/polkit-1/actions/"
echo "  sudo cp ./polkit/50-wartybix.reboot-to-windows.rules /usr/share/polkit-1/rules.d/"
echo "**********************************************************************"
