#!/bin/sh

if [ $UID != 0 ]; then
    echo "Please run this uninstaller as root."
    exit 1
fi

ICON_FILE=/usr/share/pixmaps/reboot-to-windows.svg
EXECUTABLE=/usr/bin/reboot-to-windows
WRAPPER_FILE=/usr/lib/reboot-to-windows-pkexec.sh
DESKTOP_FILE=/usr/share/applications/reboot-to-windows.desktop

rm $ICON_FILE
rm $EXECUTABLE
rm $WRAPPER_FILE
rm $DESKTOP_FILE

echo "Don't forget: If you used the polkit files for passwordless rebooting, these may still be at /usr/share/polkit-1/actions/wartybix.reboot-to-windows.policy and /usr/share/polkit-1/rules.d/50-wartybix.reboot-to-windows.rules"