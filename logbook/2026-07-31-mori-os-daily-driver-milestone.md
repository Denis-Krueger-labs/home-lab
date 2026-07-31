# Mori OS Daily-Driver Milestone

**Date:** 31 July 2026  
**System:** NixOS 26.05 virtual machine on Proxmox VE  
**Virtual machine:** VM 111, `nix01`  
**Desktop:** Hyprland through UWSM  
**Purpose:** Record the first usable Mori OS desktop state before adding a settings hub, minimize controls, custom window chrome, Spotify customization, and a login screen.

## 1. Milestone summary

The NixOS desktop has progressed from a minimal Hyprland installation into a functional themed desktop prototype.

The current system now includes:

- a layered Mori subway wallpaper
- a Quickshell dashboard embedded into the subway windows
- a second NixOS system-information panel
- dark window tint layers behind both panels
- a custom Waybar launcher strip
- a transparent floating Kitty terminal
- global Mori-colored window borders
- mouse-driven moving and resizing of windows
- working Firefox, Obsidian, and Visual Studio Code installations
- access to the Proxmox management interface from inside the VM

The system is now usable enough to preserve as a rollback point before deeper desktop integration work begins.

## 2. Virtual-machine graphics

Firefox initially exposed a graphics problem in the VM.

The original Proxmox display device was set to `Default`. Firefox produced Mesa, EGL, and Zink errors and failed to render parts of its browser interface correctly.

The Proxmox host was updated with:

```bash
apt update
apt install -y libgl1 libegl1
```

VM 111 was then changed to use:

```text
VirtIO-GPU with 3D acceleration
```

Inside NixOS, graphics support is enabled through:

```nix
hardware.graphics.enable = true;
```

This resolved the original virtual-GPU and Mesa failure.

## 3. Firefox workaround

Firefox web content rendered correctly, but its native Wayland interface failed to display tab titles, address-bar text, menu text, and some icons.

Firefox works correctly when launched through XWayland with:

```bash
env -u MOZ_ENABLE_WAYLAND GDK_BACKEND=x11 firefox --no-remote
```

A reusable wrapper was created at:

```text
/home/labadmin/.local/bin/firefox-x11
```

The wrapper launches Firefox with the working X11 backend while the rest of Hyprland remains a Wayland desktop.

A local desktop entry was created at:

```text
/home/labadmin/.local/share/applications/firefox.desktop
```

Fuzzel and the Waybar Firefox shortcut now launch the wrapper rather than the default Firefox command.

### Firefox status

| Test | Result |
|---|---|
| Web pages render | Working |
| Tab titles display | Working through XWayland |
| Address-bar text displays | Working through XWayland |
| Menus display | Working through XWayland |
| Fuzzel launcher | Working |
| Waybar shortcut | Working |
| Native Wayland backend | Currently unsuitable in this VM |

## 4. Tested daily applications

### 4.1 Firefox

Firefox is installed and functional through the custom XWayland launcher.

### 4.2 Obsidian

Obsidian is installed and tested.

Verified behavior:

- application launches
- interface renders correctly
- windows can be moved and resized
- Mori border colors are applied
- the application is suitable for vault testing and later daily use

### 4.3 Visual Studio Code

Visual Studio Code is installed and tested.

Verified behavior:

- application launches
- interface renders correctly
- folders can be opened
- integrated terminal works
- windows can be moved and resized
- the Waybar shortcut works

### 4.4 Proxmox web interface

The Proxmox web interface can be opened from Firefox inside `nix01`.

This creates a functional management path from the desktop VM back to the hypervisor. Care is required not to stop or reboot `nix01` accidentally from inside its own browser session.

### 4.5 Remaining application validation

The following applications still need full installation or validation:

- Spotify
- Discord
- WireGuard client workflow

Spotify is the next planned application because it will later provide real MPRIS data to the Mori dashboard.

## 5. Window interaction

The desktop now supports practical mouse-based window controls.

Current behavior:

| Input | Action |
|---|---|
| `Super + left mouse drag` | Move a window |
| `Super + right mouse drag` | Resize a window |
| `Super + V` | Toggle floating mode |
| `Super + C` | Close the active window |

Hyprland currently uses tiling and floating behavior rather than traditional desktop window controls.

## 6. Window borders

Kitty originally used a custom purple border while other applications inherited a different global border color.

The global Hyprland border styling was updated so applications use the same Mori palette:

```text
Active border:   #9d4dff
Inactive border: #c9c2d6 with reduced opacity
```

This gives Firefox, Obsidian, Visual Studio Code, Kitty, and future applications a consistent visual language.

## 7. Kitty terminal

Kitty was redesigned because the default terminal obscured too much of the wallpaper.

Current terminal characteristics:

- dark Mori background
- approximately 72% opacity
- no background blur
- purple active border
- hidden native title bar
- internal padding
- compact floating window
- Fastfetch colors aligned with the desktop palette

Kitty remains large enough for practical terminal use while allowing the wallpaper to remain visible.

## 8. Waybar

The original Waybar repeated information already present in the Quickshell dashboard and visually looked disconnected from the rest of the desktop.

It was redesigned into a thin launcher and status strip.

Current layout:

```text
Workspaces     MORI // ONLINE     App shortcuts     Volume     Battery     Tray
```

Current application shortcuts include:

- Firefox
- Obsidian
- Spotify
- Visual Studio Code
- Discord

Only installed applications are currently expected to launch successfully.

The battery module does not appear inside the VM because Proxmox does not expose a laptop battery. The same configuration is intended to display battery information later on the Dell XPS 16.

Waybar colors are restricted to the Mori palette:

```text
Purple:   #9d4dff
Lavender: #c9c2d6
White:    #f4f0ff
Gray:     #9e9e9e
Dark:     #18171c
```

Working copies were saved as:

```text
~/.config/waybar/config.jsonc.mori-working
~/.config/waybar/style.css.mori-working
```

## 9. Layered wallpaper and Quickshell

The complete wallpaper composition now starts automatically with Hyprland.

The startup sequence is:

```text
Hyprpaper city background
→ Waybar
→ Quickshell window tints
→ left dashboard
→ right NixOS system panel
→ transparent subway foreground artwork
```

The Quickshell configuration is stored at:

```text
/home/labadmin/.config/quickshell/mori/shell.qml
```

It is started with:

```bash
qs -p /home/labadmin/.config/quickshell/mori
```

The complete scene is launched from the Hyprland start event rather than requiring manual startup after every login.

## 10. Current observations

The following usability gaps became visible once daily applications were tested.

### 10.1 No central Settings application

A minimal Hyprland installation does not provide a unified graphical settings application.

A Mori settings hub is planned to expose tools for:

- audio and per-application volume
- network and WireGuard profiles
- appearance, fonts, icons, and cursors
- Bluetooth
- brightness and display controls
- opening the NixOS configuration

Likely underlying tools include:

```text
pavucontrol
nm-connection-editor
nwg-look
blueman
brightnessctl
```

### 10.2 No traditional minimize button

Hyprland does not currently provide a traditional minimize workflow in this configuration.

A first prototype will use a hidden special workspace as a minimize area.

A later custom Mori implementation will provide visible window controls.

### 10.3 Custom window chrome is required

The long-term desktop design calls for compositor-side Mori window chrome:

```text
[ application icon ]  Window title             [ — ] [ □ ] [ × ]
```

Planned features:

- minimize to a hidden workspace
- maximize or floating toggle
- close action
- draggable title area
- active and inactive Mori colors
- application-aware icons and titles
- compact hover animations
- optional Mori paw branding

Two implementations are planned:

1. a quick titlebar or decoration prototype
2. a custom Quickshell Mori Window Chrome implementation

Both versions will be built and compared.

### 10.4 Spotify should be customized

Spotify should match the Mori palette rather than retaining its default appearance.

Planned work:

- install and verify Spotify
- evaluate declarative Spicetify integration
- create a Mori color scheme
- expose real MPRIS track data in the left subway dashboard
- connect the dashboard playback buttons to Spotify controls

### 10.5 A login screen is still missing

The desktop currently launches into the session without a custom Mori login experience.

A future login screen should include:

- Mori subway or matching background artwork
- purple and dark-gray palette
- password entry
- clear session selection or fixed Hyprland/UWSM launch
- safe TTY recovery path

## 11. Planned next phase

The next development phase is:

1. create this Proxmox snapshot
2. finish Spotify installation and testing
3. build the Mori settings hub
4. implement prototype minimize behavior
5. test a first titlebar/window-decoration solution
6. build custom Quickshell Mori Window Chrome
7. integrate real Spotify MPRIS data
8. build the Mori login screen
9. test Discord and WireGuard
10. take another snapshot before adapting the design for the Dell XPS 16

## 12. Recommended snapshot

Recommended snapshot name:

```text
mori-daily-driver-working
```

Recommended description:

```text
Working NixOS Hyprland Mori desktop with layered Quickshell subway wallpaper, dark window tints, dual embedded panels, automatic startup, custom Waybar launcher strip, transparent floating Kitty, global Mori borders, mouse move/resize controls, VirtIO-GL graphics, Firefox XWayland wrapper, and tested Firefox, Obsidian, VS Code, and Proxmox web access. Created before settings hub, minimize controls, custom window chrome, Spotify theming, MPRIS integration, Discord, WireGuard, and login-screen work.
```

For the cleanest rollback point, shut down VM 111 before taking the snapshot and leave **Include RAM** disabled.

## 13. Rollback files already preserved

Several local backups were created during development, including working Quickshell and Waybar states. These complement the Proxmox snapshot but do not replace it.

The Proxmox snapshot remains the preferred rollback point for the entire VM state.
