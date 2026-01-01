# Reboot to Windows
This program allows the user to quickly reboot to Windows from Linux, without needing to use the boot menu to select your Windows partition.
This is useful if you are an impatient person with a slow-booting PC, as you can open the 'Windows' application from your desktop, do something else, and in a short while the Windows login screen will be displayed.
This is in contrast to a regular reboot which requires the user to select 'Windows Boot Manager' from the boot screen after rebooting, requiring supervision of the computer so that Linux doesn't automatically boot again after a timeout.

This program only works on UEFI systems.
Does not require use of GRUB, and can be used with systemd-boot too.

## How to use
### Package Managers
Arch Linux users can now install this program via [the AUR](https://aur.archlinux.org/packages/reboot-to-windows) 😊.

### Manual Install
1. Clone this repository:
```
git clone https://github.com/nardholio/reboot-to-windows
```
Alternatively, you can download from the [releases section](https://github.com/nardholio/reboot-to-windows/releases).

2. Navigate to the new repository:
```
cd reboot-to-windows/
```

3. Inspect the source code as usual before running random scripts from the internet.

3. Once happy, run the installer. To install the program for all users, run `sudo ./install.sh` (requires root permissions).

The 'Reboot to Windows' app should now be available in your desktop environment.

#### Polkit Configuration for Passwordless Execution
For seamless, passwordless execution of `reboot-to-windows`, this program uses Polkit.

The Polkit rule is *not* installed automatically. This file allows users in the `wheel` group to execute the `reboot-to-windows` command without requiring a password. If you wish to enable passwordless execution, you must manually copy this file like so:

```bash
sudo cp polkit/50-wartybix.reboot-to-windows.rules /usr/share/polkit-1/rules.d/
```

After copying the file, ensure your user account is part of the `wheel` group.

#### Uninstall
If you want to remove this program, run the uninstaller in the repository folder.
The command is `sudo ./uninstall.sh`.

#### Updating
When updating via a manual install, make sure to run the uninstaller (i.e., `uninstall.sh`) of the current version *before* pulling new changes or installing a new release.

This is because I may sometimes change where the app's files are located on the system when installed, and the uninstaller -- as well as the installer -- reflect these changes.
This issue is not present when using the Pacman package of this script.

# Attributions
Thank you to Wikimedia Commons for hosting [the file for the Windows logo](https://en.m.wikipedia.org/wiki/File:Windows_logo_-_2021.svg), which is used as a layer of the icon for this program's `.desktop` file.
