# NixOS Hyprland Mori Desktop Prototype

**Date:** 31 July 2026  
**System:** Dell OptiPlex 5070 Micro home lab  
**Platform:** Proxmox VE 9.2  
**Virtual machine:** VM 111, `nix01`  
**Goal:** Build and validate a personalized NixOS desktop environment before adapting it for the Dell XPS 16.

## 1. Current system

The virtual machine runs NixOS with Hyprland as the Wayland compositor.

Installed desktop components currently include:

- Hyprland
- UWSM
- Kitty
- Fuzzel
- Thunar
- Waybar
- Hyprpaper
- Quickshell
- Fastfetch

The system uses an English locale with a German keyboard layout.

## 2. Working desktop controls

The following shortcuts have been configured and tested:

| Shortcut | Action |
|---|---|
| `Super + Q` | Open Kitty |
| `Super + E` | Open Thunar |
| `Super + R` | Open Fuzzel |
| `Super + C` | Close the active window |
| `Super + M` | Exit Hyprland |
| `Super + V` | Toggle floating mode |
| `Super + F` | Open the Mori system terminal with Fastfetch |

## 3. Visual design

The desktop uses a layered purple cyberpunk subway scene designed for the Mori OS theme.

The wallpaper system is split into two assets:

```text
/home/labadmin/Pictures/mori/Wallpaper_BG.png
/home/labadmin/Pictures/Wallpaper_FG.png
```

The background image contains the city scene and is rendered by Hyprpaper.

The foreground image contains the subway interior, Juno, Mori, ghost kittens, moths, props, and window frames. It is rendered above the Quickshell interface so foreground objects naturally overlap the widgets.

The effective layer order is:

```text
Hyprpaper city background
├── dark window tint layers
├── left Quickshell dashboard
├── right NixOS system panel
└── transparent subway foreground artwork
```

## 4. Quickshell configuration

The active configuration is stored at:

```text
/home/labadmin/.config/quickshell/mori/shell.qml
```

Quickshell is started with:

```bash
qs -p ~/.config/quickshell/mori
```

It can be restarted during development with:

```bash
pkill qs
qs -p ~/.config/quickshell/mori
```

### 4.1 Left dashboard

The left subway window contains:

- Now Playing widget
- CPU and RAM summary
- Temperature placeholder
- Notes widget
- Live clock and date

Current geometry:

```text
X:           350
Y:           210
Width:       340
Height:      240
Perspective: -35.0 degrees
Tilt:        -1.4 degrees
```

### 4.2 Right NixOS panel

The right subway window contains a Fastfetch-inspired NixOS identity panel.

It currently displays:

- hostname and username
- NixOS version
- kernel
- Hyprland
- shell
- UWSM session
- IP address
- Mori system status

Current geometry:

```text
X:           770
Y:           155
Width:       350
Height:      220
Perspective: -18.0 degrees
Tilt:         0.7 degrees
```

### 4.3 Window tint layers

Separate dark translucent layers sit behind the two interfaces. This darkens the subway glass instead of turning the widgets into solid dark cards.

Current tint color:

```text
#9018171c
```

Left tint geometry:

```text
X:      320
Y:      170
Width:  430
Height: 335
```

Right tint geometry:

```text
X:      720
Y:      115
Width:  470
Height: 350
```

## 5. Waybar

Waybar remains visible at the top of the screen.

The theme uses:

```text
Accent purple: #9d4dff
Lavender:      #c9c2d6
Bright text:   #f4f0ff
Gray:          #9e9e9e
Dark gray:     #18171c
```

The bar currently shows workspaces, date and time, LAN address, CPU, RAM, and volume.

## 6. Problems encountered

Several issues were resolved during the desktop build:

1. The NixOS option was corrected from `console.keymap` to `console.keyMap`.
2. The correct UWSM session entry was selected.
3. A nonexistent `hl.spawn_once()` call caused Hyprland emergency mode and was replaced with a start-event handler.
4. Hyprpaper was updated to its current block-based configuration syntax.
5. Waybar launch failures over SSH were identified as display-session issues rather than Waybar configuration failures.
6. The Quickshell panel was repeatedly resized and repositioned to match the perspective of the subway windows.
7. Frosted-glass styling was rejected because it reduced clarity and made the panels appear washed out.
8. Darkening the interface cards directly created obvious rectangles. Separate window tint layers produced a more natural result.
9. An attempted second Quickshell architecture temporarily replaced the working composition. The original fullscreen layered design was restored before the right panel was added safely as a sibling layer.

## 7. Current milestone

The following items are complete:

| Item | Status |
|---|---|
| NixOS base installation | Complete |
| Hyprland desktop | Complete |
| German keyboard layout | Complete |
| Core launch shortcuts | Complete |
| Waybar theme | Complete |
| Layered subway wallpaper | Complete |
| Left dashboard prototype | Complete |
| Right NixOS panel prototype | Complete |
| Dark subway window tints | Complete |
| Fastfetch shortcut | Complete |
| Stable rollback point | Ready for snapshot |

## 8. Snapshot

A Proxmox snapshot should be created before installing the daily-use applications.

Recommended snapshot name:

```text
mori-desktop-ui-working
```

Recommended description:

```text
Working NixOS Hyprland desktop with Waybar, Hyprpaper, Quickshell, layered Mori subway wallpaper, left dashboard, right NixOS panel, window tints, and Fastfetch shortcut. Created before installing daily-use applications.
```

The snapshot does not need to include the VM memory state. The purpose is to preserve the stable disk and configuration state before the next software-installation phase.

## 9. Next software validation phase

The following applications will be installed and tested one at a time:

1. Firefox
2. Visual Studio Code
3. Obsidian
4. Spotify
5. Discord
6. WireGuard

For each application, the following should be verified:

- installation method is declarative where practical
- application launches under Wayland
- fonts and scaling are readable
- audio works where applicable
- file dialogs work
- desktop notifications work
- clipboard integration works
- GPU acceleration behaves correctly
- required login or account flow works
- configuration survives a reboot and rebuild

## 10. Planned later improvements

After the daily applications are working, possible additions include:

- real MPRIS data for Spotify
- live CPU, RAM, and temperature values
- file-backed notes
- clickable dashboard widgets
- animated moth assets
- responsive geometry for the 3840 x 2400 Dell XPS 16 display
- Quickshell autostart through the Hyprland UWSM session
- declarative packaging of wallpaper and desktop configuration
- custom Mori OS application launcher styling

## 11. Conclusion

The NixOS VM now provides a stable and visually coherent desktop prototype. The layered wallpaper and Quickshell architecture allow interface elements to appear inside the illustrated subway windows while foreground artwork remains above them.

The next phase should focus on daily usability rather than additional visual features. A snapshot at this point provides a clean rollback target before installing and testing the main application set.
