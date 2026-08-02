# Mori OS Live Widgets and Minimized Window Drawer

**Date:** 2 August 2026  
**System:** NixOS virtual machine `nix01`  
**Virtualization:** Proxmox VE 9.2  
**Desktop:** Hyprland 0.55.4 with UWSM  
**Shell layer:** Quickshell 0.3.0  
**Goal:** Replace the remaining dummy data in the subway dashboard with real system information and add a usable minimize-like workflow for desktop applications.

## 1. Starting Point

The Mori OS desktop already used the subway illustration as the visual foundation of the desktop.

Two transparent Quickshell panels were positioned inside the subway windows:

* a left dashboard containing Spotify, system statistics, notes, and a clock,
* and a right NixOS information panel.

The date and time were already generated live, but most other values were still static placeholders. The Waybar settings button had also just been added, but several backend applications initially opened with a light GTK theme.

The main files involved were:

```text
~/.config/quickshell/mori/shell.qml
~/.config/quickshell/mori-settings/shell.qml
~/.config/hypr/hyprland.lua
~/.config/hypr/mori_minimize.lua
~/.config/waybar/config.jsonc
~/.config/waybar/style.css
```

## 2. Mori Settings Button

A custom settings entry was added to Waybar. The button opens the Mori settings console, which in turn launches the required backend tools for network, appearance, displays, audio, and Bluetooth configuration.

The initial problem was that the settings module had not actually been installed. The evidence was:

```text
"custom/settings" was absent from modules-right
~/.local/bin/mori-settings-toggle did not exist
```

The installer had been made executable but had not been run.

After running the installer, the settings button appeared correctly in Waybar.

## 3. Dark GTK Settings Applications

The Mori settings console itself already used the intended dark visual design, but applications such as `nwg-look` and `nm-connection-editor` opened with a bright default GTK theme.

Dark mode was enabled through GTK and dconf preferences. The final result was substantially more consistent with the rest of the desktop:

```text
GTK theme: Adwaita-dark
Color preference: prefer-dark
```

The following backend applications now open in dark mode:

* `nwg-look`,
* `nm-connection-editor`,
* `nwg-displays`,
* `pavucontrol`,
* and other GTK settings tools.

## 4. Live System Statistics

The left subway dashboard originally contained fixed values:

```text
CPU  11%
RAM  23%
TEMP 42°
```

A helper script was created at:

```text
~/.local/bin/mori-system-stats
```

The script reads system data from Linux interfaces:

```text
/proc/stat
/proc/meminfo
/sys/class/thermal/
```

The Quickshell dashboard runs this helper every two seconds through `Quickshell.Io.Process` and parses the returned JSON.

The widget now displays:

* real CPU utilization,
* real memory utilization,
* live progress-bar widths,
* and a temperature value when a thermal sensor exists.

### 4.1 Temperature Limitation in the VM

The VM exposes no thermal zones:

```text
/sys/class/thermal/
├── cooling_device0
└── cooling_device1
```

There are no readable files matching:

```text
/sys/class/thermal/thermal_zone*/temp
```

Therefore, the temperature display correctly shows an unavailable state instead of a fabricated value.

This is expected in the current Proxmox virtual machine. Once Mori OS runs directly on the Dell XPS 16, the guest limitation disappears and the Linux hardware sensor drivers may provide real temperature data.

## 5. Live Spotify Widget

The Spotify panel previously contained static placeholder metadata:

```text
Title:  The Summoning
Artist: Sleep Token
Source: Spotify
```

The panel was connected to Spotify through the MPRIS D-Bus interface exposed by Quickshell.

The widget now supports:

* current track title,
* current artist,
* album artwork,
* current playback state,
* previous track,
* play and pause,
* and next track.

When Spotify is not running, the widget displays an offline state rather than stale metadata.

No Spotify API, token, backend server, or external web service is required. The widget reads the local media session exposed by the running Spotify client.

## 6. Script Portability Problems

Two small installer issues occurred while deploying the Spotify patch.

### 6.1 Python Was Not in PATH

The initial installer used Python to patch the QML file, but the NixOS user environment did not expose `python3` globally:

```text
-bash: python3: command not found
```

The corrected installer automatically starts a temporary Nix shell containing Python:

```text
nix shell nixpkgs#python3
```

This avoided permanently adding Python to the system configuration solely for a one-time patch.

### 6.2 Windows CRLF Line Endings

A copied shell script contained Windows line endings. Linux interpreted the shebang as:

```text
bash\r
```

This produced:

```text
env: ‘bash\r’: No such file or directory
```

The file was repaired with:

```bash
sed -i 's/\r$//' message.sh
```

This is a useful reminder to preserve Unix LF line endings for scripts transferred from Windows to NixOS.

## 7. Hyprland Configuration Discovery

The first minimize attempts were added to:

```text
~/.config/hypr/hyprland.conf
```

Hyprland reloaded without errors, but no new bindings appeared in `hyprctl binds`.

Further inspection showed that the active configuration was actually:

```text
~/.config/hypr/hyprland.lua
```

The running command was:

```text
Hyprland --watchdog-fd 4
```

No explicit `.conf` file was passed, and Hyprland 0.55.4 loaded the Lua configuration by default.

The old `.conf` file therefore remained present but was not the active source of the desktop configuration.

## 8. Invalid Lua Comment and Recovery

The first drawer implementation accidentally included a C-style block comment:

```text
/* comment */
```

This is invalid Lua syntax and caused Hyprland to enter emergency mode.

The desktop was recovered by restoring the timestamped backup created immediately before the change.

Valid Lua comments use either:

```lua
-- single-line comment
```

or:

```lua
--[[
multiline comment
]]
```

After restoring the backup, `hyprctl configerrors` returned no output, confirming that the configuration was healthy again.

## 9. Minimized Window Drawer

Hyprland does not implement conventional desktop minimization. A minimize-like workflow was therefore created with a named special workspace:

```text
special:minimized
```

The implementation lives in a separate module:

```text
~/.config/hypr/mori_minimize.lua
```

The main Hyprland configuration loads it with:

```lua
require("mori_minimize")
```

This keeps the main `hyprland.lua` file cleaner and makes future changes easier to isolate and roll back.

### 9.1 Final Keybindings

```text
Super + N            Move the focused application into the minimized drawer
Super + Shift + N    Open or close the minimized drawer
Super + L            Select the next minimized application
Super + K            Select the previous minimized application
Super + Enter        Restore the selected application
```

The drawer supports multiple minimized applications at the same time.

A normal workflow is:

1. Focus Firefox and press `Super + N`.
2. Focus Spotify and press `Super + N`.
3. Press `Super + Shift + N` to open the drawer.
4. Use `Super + K` or `Super + L` to select a window.
5. Press `Super + Enter` to restore the selected application.

The remaining minimized applications stay inside the drawer.

### 9.2 Why Tab Was Replaced

The first design used:

```text
Super + Tab
Super + Shift + Tab
```

The shifted variant was also tested as the XKB symbol:

```text
ISO_Left_Tab
```

Hyprland loaded the bindings, but Tab-based switching still did not behave reliably in this environment. The drawer controls were therefore moved to `K` and `L`, which worked consistently and did not collide with the existing directional focus bindings.

## 10. Hyprland IPC Through SSH

Running `hyprctl` through SSH initially failed with:

```text
HYPRLAND_INSTANCE_SIGNATURE not set!
```

Later, an old SSH environment also pointed to a stale Hyprland socket after the graphical session restarted.

The active instance can be found under:

```text
/run/user/1000/hypr/
```

The correct instance signature must be exported before using `hyprctl` remotely.

A successful remote reload produced:

```text
ok
```

A healthy configuration produced an empty result for:

```bash
hyprctl configerrors
```

## 11. Current Status

| Component | Status |
|---|---|
| Subway foreground composition | Working |
| Left dashboard positioning | Working |
| Right NixOS panel positioning | Working |
| Live clock and date | Working |
| Live CPU utilization | Working |
| Live memory utilization | Working |
| CPU temperature in VM | Unavailable by design |
| Live Spotify title and artist | Working |
| Spotify album artwork | Working |
| Spotify media controls | Working |
| Mori Waybar settings button | Working |
| Dark GTK settings applications | Working |
| Multi-window minimized drawer | Working |
| Notes widget | Still static |
| Right NixOS information panel | Still partly static |
| XPS hardware configuration | Not started |
| Mori login screen | Not started |

## 12. Current Configuration Structure

```text
~/.config/
├── hypr/
│   ├── hyprland.lua
│   ├── mori_minimize.lua
│   ├── monitors.conf
│   ├── workspaces.conf
│   └── hyprpaper.conf
│
├── quickshell/
│   ├── mori/
│   │   └── shell.qml
│   └── mori-settings/
│       └── shell.qml
│
└── waybar/
    ├── config.jsonc
    └── style.css

~/.local/bin/
├── mori-system-stats
└── mori-settings-toggle
```

Timestamped backups were created before the major Hyprland and Quickshell changes.

## 13. Lessons Learned

The most important lesson was to inspect the active configuration before editing it.

The presence of `hyprland.conf` did not mean that Hyprland was using it. The running version used `hyprland.lua`, and bindings added to the inactive file could never work.

Other useful lessons were:

* always run the installer after making it executable,
* verify the exact Quickshell profile path,
* expect physical temperature data to be absent in a VM,
* use local MPRIS instead of an unnecessary Spotify API integration,
* preserve Unix line endings for Linux scripts,
* do not assume Python exists globally on NixOS,
* use timestamped backups before changing the compositor configuration,
* keep optional Hyprland features in separate Lua modules,
* and confirm success with both `hyprctl configerrors` and `hyprctl binds`.

## 14. Next Steps

The next Mori OS tasks are intentionally separated from this checkpoint.

### 14.1 Remaining Live Dashboard Data

The next widget work should replace the remaining static values in the right subway window with real data:

* username,
* hostname,
* NixOS version,
* kernel version,
* shell,
* session type,
* active IP address,
* and system state.

The notes widget also needs a real source instead of hardcoded text.

### 14.2 Login Screen

A Mori-themed login screen can be designed after the desktop widgets are complete and stable.

### 14.3 Dell XPS 16 Hardware Support

The physical laptop configuration will be developed only after installing or booting NixOS on the actual XPS and reading its real PCI and USB device identifiers.

Planned hardware areas include:

* Intel graphics,
* NVIDIA RTX 4070 Laptop GPU,
* Wi-Fi,
* Bluetooth,
* audio,
* webcam,
* fingerprint reader,
* touchscreen,
* Thunderbolt,
* power management,
* suspend,
* and firmware updates.

A later Mori settings page should expose selected hardware capabilities as declarative enable or disable options. Critical devices must be protected from unsafe live removal, and each setting should clearly state whether it requires a service restart, NixOS rebuild, or reboot.

## 15. Checkpoint Result

This session converted the subway dashboard from a mostly visual mock-up into a partially live desktop interface.

The system monitor and Spotify widget now read real local data, the settings launcher is usable and visually consistent, and applications can be hidden and restored through a multi-window drawer without being closed.

The current state is stable enough to treat as a documented checkpoint before continuing with the remaining live data, login screen, and XPS hardware work.
