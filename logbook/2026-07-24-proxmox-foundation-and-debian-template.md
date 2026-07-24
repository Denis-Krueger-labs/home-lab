# Proxmox Foundation and Debian Template Setup

**Date:** 24 July 2026  
**End time:** 03:41  
**System:** Dell OptiPlex 5070 Micro  
**Platform:** Proxmox VE 9.2  
**Goal:** Finish the basic Proxmox setup, configure backups, and create a reusable Debian 13 server template.

## 1. Starting Point

Proxmox VE 9.2 had already been installed on the internal 1 TB SSD.

The system was reachable through the Proxmox web interface at:

```text
https://192.168.178.53:8006
```

The Dell correctly recognized the Intel Core i5-9500T, 32 GB RAM, the internal 1 TB SSD, and the Ethernet connection.

The Proxmox node was healthy, but the default enterprise repositories were enabled without a subscription.

## 2. Repository Configuration

The Proxmox enterprise repositories for PVE and Ceph were disabled.

The Proxmox no-subscription repository was enabled instead:

```text
http://download.proxmox.com/debian/pve
```

The normal Debian Trixie, Trixie Updates, and Trixie Security repositories remained enabled.

The warning that the no-subscription repository is not recommended for production use is expected for this home lab.

## 3. Proxmox Update

The package lists were refreshed and all available updates were installed.

The Dell was restarted afterwards.

The updated Proxmox summary showed:

```text
Kernel: Linux 7.0.14-6-pve
Manager: pve-manager/9.2.5
Memory: 31.13 GiB
IO delay: 0.00%
```

The node restarted successfully and remained reachable through the web interface.

## 4. Backup Drive Setup

The external 1 TB backup drive appeared as:

```text
/dev/sdb
Model: ST1000LM025_HN-M101ABB
```

The drive was confirmed to be empty.

Its old partitions were removed and a new ext4 partition was created:

```text
/dev/sdb1
```

Proxmox mounted the drive at:

```text
/mnt/pve/backup-ssd
```

It was added as directory storage with the ID:

```text
backup-ssd
```

The storage was restricted to backup files. Live VM disks remain on `local-lvm`.

## 5. Automatic Backup Job

A weekly backup job was created with the following settings:

```text
Node:           pve
Storage:        backup-ssd
Schedule:       Sunday at 01:00
Selection mode: All
Compression:    ZSTD
Mode:           Snapshot
Retention:      Keep last 3
```

The job is enabled and will automatically include future VMs.

## 6. Debian Installation Image

The following ISO was uploaded to `local (pve)`:

```text
debian-13.6.0-amd64-netinst.iso
```

## 7. Debian Template VM

A new VM was created:

```text
VM ID: 100
Name: debian-gold
```

The hardware configuration was:

| Setting | Value |
|---|---|
| Machine | q35 |
| Firmware | OVMF (UEFI) |
| EFI disk | Enabled |
| Secure Boot keys | Disabled |
| SCSI controller | VirtIO SCSI single |
| CPU | 2 cores, x86-64-v2-AES |
| Memory | 2 GB |
| Disk | 32 GB on local-lvm |
| Disk options | Discard and IO thread enabled |
| Network | VirtIO on vmbr0 |
| Firewall flag | Enabled |
| QEMU guest agent support | Enabled |

The VM was intended to become a reusable server template, not a normal workload.

## 8. Debian Installation

The graphical installer was used, but no desktop environment was installed.

The selected software was:

* SSH server,
* standard system utilities,
* no desktop,
* and no web server.

The system identity was:

```text
Hostname: tmpl-debian
Domain:   left empty
User:     labadmin
```

The disk used automatic guided partitioning with:

* an EFI partition,
* one ext4 root partition,
* and swap.

## 9. Installed Packages

The following packages were installed and verified:

```text
sudo
openssh-server
qemu-guest-agent
cloud-init
cloud-initramfs-growroot
curl
wget
vim
git
ca-certificates
```

The `labadmin` account was added to the `sudo` group.

The following check returned `root`:

```bash
sudo whoami
```

## 10. Service and System Checks

The following checks passed:

| Check | Result |
|---|---|
| SSH | Enabled and active |
| QEMU guest agent | Active |
| Cloud-init | Installed |
| Failed systemd services | None |
| Package updates | None remaining |
| Network | DHCP address received |
| Root filesystem | Approximately 29 GB, 6% used |

The VM received:

```text
192.168.178.57/24
```

## 11. Language Configuration

The Debian installation initially used German system messages.

The intended locale was changed to:

```text
LANG=en_US.UTF-8
LANGUAGE=en_US:en
```

A typo temporarily configured `en_US.UFT-8`. This was corrected before the template was finished.

The keyboard layout remains German.

## 12. Template Cleanup

Machine-specific information was removed before conversion:

* cloud-init instance data,
* the machine ID,
* SSH host keys,
* package cache,
* and login history.

During cleanup, `apt autoremove` unexpectedly removed `sudo`.

The package was reinstalled and the `labadmin` account was added back to the `sudo` group.

This showed that `apt autoremove` should always be reviewed before use on a minimal template.

## 13. Proxmox Template Conversion

After the final checks, the VM was powered off.

The Debian ISO was ejected.

A Cloud-Init drive was added on `local-lvm`.

The boot order was reduced to:

```text
1. scsi0
```

The VM was then converted into a Proxmox template.

The finished template is:

```text
100 (debian-gold)
```

## 14. Current Status

| Task | Status |
|---|---|
| Proxmox repositories configured | Complete |
| Proxmox updated | Complete |
| Healthy reboot verified | Complete |
| Backup drive configured | Complete |
| Weekly backup job configured | Complete |
| Debian ISO uploaded | Complete |
| Debian base installed | Complete |
| Required packages verified | Complete |
| SSH configured | Complete |
| QEMU guest agent active | Complete |
| Cloud-init installed | Complete |
| Debian template created | Complete |
| First real server clone | Not started |

## 15. Problems Encountered

1. The backup enclosure reported a different internal drive model than expected.
2. Debian did not initially include `sudo`.
3. The locale was temporarily mistyped as `UFT-8`.
4. `apt autoremove` removed `sudo`.
5. The QEMU guest agent produced confusing messages before being confirmed active.
6. Pasting long command blocks into the Proxmox console was awkward.

All issues were resolved before the template was converted.

## 16. Lessons Learned

Backups should be configured before important VMs are deployed.

A template needs to be checked carefully because every mistake may be copied into future systems.

Minimal installations can treat manually useful packages as removable dependencies, so `apt autoremove` should not be accepted blindly.

Cloud-init, SSH, and the QEMU guest agent make the template much more useful than a plain Debian installation.

## 17. Next Step

The next task is to clone the Debian template into the first real infrastructure server:

```text
VM ID:     200
Name:      docker01
Clone type: Full clone
Storage:   local-lvm
```

Work stopped at 03:41 because the final exam begins approximately five hours later.
