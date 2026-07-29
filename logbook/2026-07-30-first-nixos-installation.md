# First NixOS Installation

**Date:** 2026-07-30  
**VM ID:** 111  
**Hostname:** `nix01`  
**Platform:** Proxmox VE  
**Result:** Successful

## Objective

The objective was to deploy the first NixOS virtual machine in the home lab and create a working declarative base configuration.

The system was installed manually from the NixOS minimal ISO to gain practical experience with:

- GPT partitioning
- EFI boot
- Linux filesystems
- NixOS configuration generation
- Declarative package and service management
- System generations and rebuilds
- SSH host-key verification
- Proxmox guest integration

The VM will serve as a safe development environment for a future NixOS installation on a Dell XPS 16 9640.

The intended graphical environment is Hyprland. The VM will be used to build and test the Hyprland configuration before applying it to physical laptop hardware.

## Virtual Machine Configuration

| Setting | Value |
|---|---|
| VM ID | 111 |
| VM name | `nix01` |
| Machine type | Q35 |
| Firmware | OVMF UEFI |
| Secure Boot keys | Disabled |
| CPU | 2 virtual cores |
| CPU type | Host |
| Memory | 4096 MiB |
| Disk | 40 GiB |
| Disk controller | VirtIO SCSI Single |
| Network model | VirtIO |
| Network bridge | `vmbr0` |
| Proxmox firewall flag | Enabled |
| QEMU Guest Agent | Enabled |

After installation, the NixOS ISO was detached and only `scsi0` was retained in the VM boot order. Network boot was disabled.

## Operating System

| Component | Value |
|---|---|
| Distribution | NixOS 26.05 |
| Architecture | `x86_64-linux` |
| Kernel | Linux 7.1.5 |
| Kernel package | `linuxPackages_latest` |
| Bootloader | systemd-boot |
| Root filesystem | ext4 |
| EFI filesystem | FAT32 |

The installation medium was booted using its Linux 7.1.5 option.

The installed system was also configured to use the latest kernel package available in the selected NixOS release:

    boot.kernelPackages = pkgs.linuxPackages_latest;

Using a recent kernel is especially relevant for the later Dell XPS installation because the laptop contains newer hardware such as a touchscreen, fingerprint reader, NVIDIA graphics and a digital function-key row.

## Disk Preparation

The virtual disk appeared as `/dev/sda`.

A GPT partition table was created and the disk was divided into two partitions:

| Partition | Size | Filesystem | Mount point | Purpose |
|---|---:|---|---|---|
| `/dev/sda1` | 512 MiB | FAT32 | `/boot` | EFI System Partition |
| `/dev/sda2` | Remaining space | ext4 | `/` | NixOS root filesystem |

The EFI partition was assigned the label `BOOT`.

The root filesystem was assigned the label `nixos`.

The disk was partitioned using:

    sudo parted /dev/sda -- mklabel gpt
    sudo parted /dev/sda -- mkpart ESP fat32 1MiB 513MiB
    sudo parted /dev/sda -- set 1 esp on
    sudo parted /dev/sda -- mkpart primary ext4 513MiB 100%

The filesystems were created using:

    sudo mkfs.fat -F 32 -n BOOT /dev/sda1
    sudo mkfs.ext4 -L nixos /dev/sda2

The partitions were mounted for installation using:

    sudo mount /dev/disk/by-label/nixos /mnt
    sudo mkdir -p /mnt/boot
    sudo mount /dev/disk/by-label/BOOT /mnt/boot

## Configuration Generation

The initial system configuration was generated using:

    sudo nixos-generate-config --root /mnt

This created:

- `/mnt/etc/nixos/configuration.nix`
- `/mnt/etc/nixos/hardware-configuration.nix`

After installation, these files became available under:

- `/etc/nixos/configuration.nix`
- `/etc/nixos/hardware-configuration.nix`

`configuration.nix` defines the desired operating-system state.

`hardware-configuration.nix` contains detected virtual hardware modules, filesystem UUIDs and mount definitions specific to VM 111.

## Declarative System Configuration

The initial configuration defines:

- Hostname `nix01`
- NetworkManager
- Time zone `Europe/Berlin`
- English system locale
- German console keyboard layout
- Administrative user `labadmin`
- OpenSSH
- QEMU Guest Agent
- Latest available Linux kernel package
- systemd-boot
- Git
- Vim
- wget
- curl
- Fastfetch

The regional configuration keeps the operating-system language in English while using a German keyboard layout:

    time.timeZone = "Europe/Berlin";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "de";

The administrative account is declared as:

    users.users.labadmin = {
      isNormalUser = true;
      description = "Lab Administrator";
      extraGroups = [ "wheel" ];
    };

The user belongs to the `wheel` group and therefore has sudo access.

The enabled services are:

    services.openssh.enable = true;
    services.qemuGuest.enable = true;

The installed base packages are:

    environment.systemPackages = with pkgs; [
      curl
      fastfetch
      git
      vim
      wget
    ];

The compatibility baseline is:

    system.stateVersion = "26.05";

This value records the NixOS version used when the machine was first installed. It is not an update channel and should not normally be changed during future upgrades.

## Installation

The system was installed using:

    sudo nixos-install --root /mnt --no-root-passwd

The root account was intentionally left without a password.

A password was assigned to the normal administrative account using:

    sudo nixos-enter --root /mnt -c 'passwd labadmin'

After installation:

1. The VM was powered off.
2. The installer ISO was detached.
3. Network boot was removed from the boot order.
4. The VM was booted from `scsi0`.
5. Login as `labadmin` succeeded.

## Issue 1: Keyboard Layout

The live installer initially used a US keyboard layout.

The installer console was changed to German using:

    loadkeys de

The Proxmox console layout also needed to be configured correctly to avoid keyboard input being translated twice.

The permanent NixOS console layout was configured as:

    console.keyMap = "de";

The system language and locale remain English.

## Issue 2: Incorrect NixOS Option Name

The first installation attempt failed because the console keyboard option was entered as:

    console.keymap = "de";

NixOS rejected the unknown option and suggested the correct attribute:

    console.keyMap = "de";

After correcting the capital `M`, configuration evaluation succeeded and the installation continued.

This demonstrated that NixOS validates the desired configuration before installing or activating it instead of silently ignoring an invalid setting.

## Issue 3: EFI Partition Permissions

During installation, systemd-boot warned that the EFI partition allowed its random-seed file to be read by other users.

The generated FAT mount options were initially:

    options = [ "fmask=0022" "dmask=0022" ];

They were changed to:

    options = [ "fmask=0077" "dmask=0077" ];

The updated system configuration was applied using:

    sudo nixos-rebuild switch

The existing FAT filesystem initially remained mounted with its previous options.

After rebooting, `/boot` was remounted with the new restrictive permissions.

The active mount options were verified using:

    findmnt /boot

## First Declarative Rebuild

The EFI mount permission change was the first configuration update applied using the standard NixOS workflow:

1. Edit the desired configuration.
2. Evaluate the configuration.
3. Build a new system generation.
4. Activate the new generation.
5. Reboot when required.
6. Verify the resulting system state.

The rebuild completed successfully.

NixOS retained the previous system generation, allowing rollback if the new configuration failed.

## Network and SSH Verification

The VM received the IPv4 address:

    192.168.178.69/24

The virtual network interface was detected as:

    ens18

SSH access was tested from the Windows laptop using:

    ssh labadmin@192.168.178.69

The address had previously belonged to another SSH host.

The local SSH client therefore displayed a warning that the remote host identification had changed.

The obsolete entry was removed from the Windows `known_hosts` file using:

    ssh-keygen -R 192.168.178.69

The new NixOS host fingerprint was then accepted and SSH login succeeded.

This demonstrated that SSH identifies a server using its cryptographic host key rather than trusting an IP address alone.

## System Verification

The completed installation was checked using:

    hostname
    uname -r
    ip addr
    systemctl status qemu-guest-agent --no-pager
    sudo whoami

The following results were confirmed:

| Test | Result |
|---|---|
| Boot from virtual disk | Passed |
| Hostname is `nix01` | Passed |
| Kernel version is 7.1.5 | Passed |
| IPv4 connectivity | Passed |
| SSH login | Passed |
| `labadmin` login | Passed |
| Sudo access | Passed |
| QEMU Guest Agent | Active |
| Declarative rebuild | Passed |
| Reboot after rebuild | Passed |
| EFI permission change | Verified |
| Fastfetch execution | Passed |

## Fastfetch

Fastfetch was added declaratively to the system package list.

It successfully displayed:

- NixOS version
- Kernel version
- Hostname
- QEMU/KVM platform
- CPU allocation
- Memory usage
- Filesystem usage
- Local IP address
- Shell and terminal information
- NixOS ASCII logo

Fastfetch provides a quick visual check of the VM state and the traditional ceremonial NixOS terminal flex.

## Repository Layout

The deployed configuration is stored in the home-lab repository under:

    configs/
    └── nixos/
        └── nix01/
            ├── configuration.nix
            └── hardware-configuration.nix

The installation report is stored under:

    docs/
    └── logs/
        └── 2026-07-30-first-nixos-installation.md

`hardware-configuration.nix` is machine-specific.

It contains filesystem UUIDs and virtual hardware information belonging to VM 111.

## Intended Desktop Environment

The intended graphical environment for the project is Hyprland.

Hyprland was selected because it supports the desired highly customized Wayland-based desktop and provides practical experience with:

- Wayland compositors
- Declarative desktop configuration
- Tiling window management
- Workspaces
- Keybindings
- Status bars
- Application launchers
- Lock screens
- Idle handling
- Screen sharing
- Touchscreen input
- Laptop gestures
- NVIDIA configuration
- Hybrid graphics
- Custom theming

The initial Hyprland environment will be developed inside `nix01` before being adapted for the Dell XPS 16 9640.

The future desktop stack may include:

- Hyprland
- Waybar
- Kitty
- Fuzzel or Wofi
- Hyprlock
- Hypridle
- Hyprpaper
- PipeWire
- xdg-desktop-portal-hyprland
- Home Manager

The exact components will be selected and tested incrementally.

## Planned Laptop-Specific Work

The later Dell XPS 16 9640 installation will require testing and configuration for:

- High-resolution display scaling
- Touchscreen support
- Touchpad gestures
- Digital function-key row
- Fingerprint reader
- Webcam
- Audio
- Suspend and resume
- Battery and power management
- Intel integrated graphics
- NVIDIA RTX 4070 hybrid graphics
- External displays
- Wayland screen sharing

The VM cannot reproduce these physical hardware requirements, but it provides a safe environment for developing the reusable NixOS and Hyprland configuration structure.

## Result

The first NixOS machine was successfully deployed and integrated into the home lab.

The VM now provides:

- A declaratively managed operating system
- UEFI boot through systemd-boot
- A recent Linux kernel
- Working network connectivity
- Secure remote SSH access
- Administrative sudo access
- Proxmox QEMU Guest Agent integration
- Restrictive EFI filesystem permissions
- Reproducible system generations
- Rollback support
- A version-controlled base configuration
- A safe environment for Hyprland development

The next phase will focus on converting the configuration to a cleaner modular structure and deploying the first Hyprland session inside the VM.
