# Mori OS Settings Control Node

**Date:** 2026-08-01  
**System:** NixOS 26.05  
**Host:** `nix01`  
**Desktop:** Hyprland + UWSM  
**VM:** Proxmox VM 111

## Milestone Summary

Mori OS now has the foundations of a custom terminal-style settings interface instead of relying on a full desktop environment such as GNOME or KDE.

The current system includes a working dark GTK theme, a consistent cursor theme, individual graphical settings tools, and a custom Quickshell settings window with responsive layouts and transparent Mori styling.

## System Configuration Changes

The NixOS configuration now includes the following settings backends:

- `pavucontrol` for PipeWire audio devices and per-application volume
- `nm-connection-editor` through `networkmanagerapplet`
- `nwg-look` for GTK themes, fonts, icons, and cursors
- `nwg-displays` for monitor arrangement and display settings
- `blueman` for Bluetooth management
- `brightnessctl` for laptop backlight control
- `hyprpolkitagent` for authentication prompts

Bluetooth support is enabled declaratively:

```nix
hardware.bluetooth.enable = true;
services.blueman.enable = true;
```

The Proxmox VM currently exposes no Bluetooth controller. Therefore:

- `bluetooth.service` is enabled but inactive
- `bluetoothctl list` returns no controllers
- this is expected VM behavior, not a broken configuration

## Dark Mode

GTK applications now use a dark appearance through `nwg-look` and GNOME interface preferences.

Configured values:

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
```

This affects applications such as:

- PulseAudio Volume Control
- Network Connections
- Blueman
- GTK file dialogs
- other GTK utilities

Applications with their own theme systems, including Firefox, VS Code, Obsidian, and Spotify, still require their own Mori-specific styling.

## Cursor Theme

The original cyan loading cursor was replaced with:

```text
Bibata-Modern-Classic
Size 24
```

The theme is installed through:

```nix
mint-cursor-themes
```

The UWSM environment contains:

```bash
export XCURSOR_THEME="Bibata-Modern-Classic"
export XCURSOR_SIZE="24"
unset HYPRCURSOR_THEME
unset HYPRCURSOR_SIZE
```

The same cursor was selected in `nwg-look` for GTK applications.

## Mori Settings

A separate Quickshell configuration was created at:

```text
~/.config/quickshell/mori-settings/shell.qml
```

It is launched with:

```bash
qs -p ~/.config/quickshell/mori-settings
```

### Current Features

- transparent smoked-terminal background
- Mori purple border and terminal palette
- responsive Qt layouts
- resizable floating window
- custom title bar
- minimize, maximize, and close controls
- mouse-driven window movement
- keyboard navigation
- command inspector
- scrollable settings command list
- six settings targets:
  - Audio
  - Network and VPN
  - Appearance
  - Displays
  - Bluetooth
  - NixOS configuration

### Keyboard Controls

```text
1–6       select a settings target
Up/Down   navigate the command list
Enter     launch the selected tool
Q/Escape  close Mori Settings
```

## Bluetooth Handling

The initial Bluetooth button launched `blueman-manager` unconditionally, which produced a large BlueZ error dialog in the VM.

The updated design uses Quickshell 0.3.0 Bluetooth state detection:

```qml
import Quickshell.Bluetooth
```

Expected states:

```text
NO_CONTROLLER   no Bluetooth adapter exposed to the VM
POWERED_OFF     adapter detected but disabled
READY           adapter enabled
READY // N CONNECTED
```

When no controller exists, the Bluetooth command is blocked and the UI explains why. This prevents the Blueman error dialog.

## Working Daily Applications

The following applications are installed and tested:

- Firefox through the custom XWayland wrapper
- Obsidian
- VS Code
- Spotify
- Kitty
- Thunar
- Proxmox web interface through Firefox

## Current Configuration Backup

The existing backup bundle is stored as:

```text
config_daily/
```

Because Mori Settings, dark mode, Bluetooth support, and the cursor theme were added after the original bundle was created, the repository copy should now be refreshed with the latest files.

Important paths:

```text
/etc/nixos/configuration.nix
~/.config/quickshell/mori-settings/shell.qml
~/.config/uwsm/env
~/.config/hypr/hyprland.lua
~/.config/waybar/config.jsonc
~/.config/waybar/style.css
~/.config/kitty/kitty.conf
```

## Next Steps

1. Verify the Bluetooth-aware Mori Settings build.
2. Add a launcher script and Waybar settings button.
3. Build Mori Snap layouts for the maximize button.
4. Add three window layout modes inspired by Windows snap layouts.
5. Prototype global Mori Window Chrome.
6. Theme Spotify with the Mori palette.
7. Connect Spotify MPRIS data to the subway dashboard.
8. Build the Mori OS login screen.

## Suggested Commit

```text
Add Mori Settings control node and desktop theming
```
