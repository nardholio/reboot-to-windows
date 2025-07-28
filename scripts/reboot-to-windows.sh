#!/bin/sh

set -e # Halts the program if error occurs (i.e., not getting sudo permission)

# Gets list of boot options.
# Then searches for line containing 'Windows' in these options (case
# insensitive).
# Gets the 'Boot____*' value of this line.
# Extracts the 4-digit number from this value.
# If unsuccessful, the variable is set to -1.
WINDOWS_BOOT=`efibootmgr | grep -i Windows | grep -Eo "Boot(.*?\*)" | grep -Eo "[0-9]{4}" || echo -1`

if [ "$WINDOWS_BOOT" == "-1" ]; then #If Windows was not found:
	# Display notification.
	notify-send -a Windows "Reboot Unsuccessful" \
	"The Windows boot option was not found on the system."

	exit 1 # Exit the program with code 1.
fi

NEXT_BOOT=`efibootmgr | grep BootNext | grep -Eo [0-9]{4} || echo -1`

if [ "$NEXT_BOOT" != "$WINDOWS_BOOT" ]; then
	pkexec /usr/lib/reboot-to-windows-pkexec.sh set-boot $WINDOWS_BOOT # Set next boot to Windows boot
fi

case $DESKTOP_SESSION in
	gnome) # If user running GNOME:
		gnome-session-quit --reboot ;; # Show gnome reboot prompt
	plasma) # If user running KDE Plasma:
		# Check for 'qdbus' command. If empty, set to -1.
		QDBUS=`which qdbus 2>/dev/null || echo -1`
		if [ "$QDBUS" = "-1" ]; then # If qdbus command not found:
			pkexec /usr/lib/reboot-to-windows-pkexec.sh reboot # Generic reboot
		else
			# Show KDE Plasma reboot prompt
			qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot
		fi
		;;
	*) # If running another desktop environment:
		pkexec /usr/lib/reboot-to-windows-pkexec.sh reboot ;; # Generic reboot
esac
