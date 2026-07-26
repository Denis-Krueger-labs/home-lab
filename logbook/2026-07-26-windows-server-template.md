# Windows Server 2025 Template Setup

**Date:** 26 July 2026  
**System:** Dell OptiPlex 5070 Micro  
**Platform:** Proxmox VE 9.2  
**Virtual machine:** VM 110, `windows-server-gold`  
**Goal:** Create a clean and reusable Windows Server 2025 template for future Windows Server systems such as the first domain controller.

## 1. Installation Preparation

The Windows Server template was created after the Proxmox host, backup storage, automatic backup job, and Debian template had already been configured.

The following ISO files were uploaded to the local Proxmox ISO storage:

```text
Windows Server 2025 Evaluation, German
virtio-win-0.1.285.iso
```

The Windows Server ISO provided the operating system installer.

The VirtIO ISO provided the drivers required for Windows to use the virtual disk, network adapter, QEMU guest agent, and other virtual hardware presented by Proxmox.

## 2. Virtual Machine Creation

A new virtual machine was created with the following identity:

```text
VM ID: 110
Name: windows-server-gold
```

The VM was designed as a reusable base template rather than as a working domain controller or application server.

No Windows Server roles were installed.

## 3. Virtual Hardware Configuration

| Setting | Value |
|---|---|
| Machine type | q35 |
| Firmware | OVMF, UEFI |
| EFI disk | Enabled |
| Secure Boot keys | Pre-enrolled |
| TPM | Version 2.0 |
| SCSI controller | VirtIO SCSI single |
| CPU | 4 vCPUs |
| CPU type | x86-64-v2-AES |
| Memory | 6 GB |
| Minimum ballooned memory | 2 GB |
| Main disk | 80 GB |
| Disk storage | local-lvm |
| Disk bus | SCSI |
| Discard | Enabled |
| IO thread | Enabled |
| SSD emulation | Enabled |
| Network adapter | VirtIO |
| Network bridge | vmbr0 |
| Proxmox firewall flag | Enabled |
| QEMU guest agent support | Enabled |

The 80 GB disk was chosen to provide enough room for Windows Server, updates, logs, the component store, and future server roles without making the template unnecessarily large.

Because `local-lvm` uses thin provisioning, the full 80 GB is not consumed immediately.

## 4. Installation Media

The VM used two virtual CD/DVD drives:

```text
ide2: Windows Server 2025 Evaluation ISO
ide0: VirtIO driver ISO
```

The Windows Server ISO was placed first in the boot order for the initial installation.

The VirtIO ISO remained attached so the required storage driver could be loaded during Windows Setup.

## 5. Windows Server Installation

Windows Server 2025 Standard Evaluation with Desktop Experience was selected.

Desktop Experience was chosen for the first Windows Server template because it provides easier access to:

* Server Manager,
* Event Viewer,
* Device Manager,
* Windows Update,
* graphical role installation,
* and local troubleshooting tools.

A Server Core template may be created later for PowerShell and remote-management practice.

## 6. VirtIO Storage Driver

During Windows Setup, no installation disk was initially displayed.

This happened because Windows did not yet contain the VirtIO SCSI storage driver.

The driver was loaded from the VirtIO ISO using:

```text
vioscsi
└── 2k25
    └── amd64
```

After loading the Red Hat VirtIO SCSI driver, the 80 GB virtual disk appeared and installation continued normally.

Windows created the required EFI, recovery, and system partitions automatically.

## 7. VirtIO Guest Tools

After installation, the VirtIO guest tools were installed from the VirtIO ISO.

The installer used was:

```text
virtio-win-guest-tools.exe
```

The default components were installed.

This added the required virtual hardware drivers and the QEMU guest agent.

The VM was restarted afterwards.

## 8. QEMU Guest Agent Verification

The QEMU guest agent was verified through the Proxmox web interface.

Proxmox successfully displayed information from inside the guest, including IP addresses and memory information.

This confirmed that the QEMU guest agent was running correctly.

## 9. Network Configuration

The Windows Server VM received:

```text
192.168.178.55
```

The server was connected directly to `vmbr0` during template preparation.

This placed it temporarily on the normal home network.

The final lab design may later place Windows and Linux systems behind an OPNsense router on isolated virtual networks.

## 10. OpenSSH Configuration

OpenSSH Server was installed, but the `sshd` service was initially stopped.

The service was started and configured to start automatically:

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

The service status was verified:

```powershell
Get-Service sshd
```

The result showed:

```text
Running
```

Port 22 was also confirmed to be listening on IPv4 and IPv6:

```powershell
Get-NetTCPConnection -LocalPort 22 -State Listen
```

## 11. Windows Firewall and Network Profile

The OpenSSH firewall rule already existed:

```text
OpenSSH-Server-In-TCP
```

The rule was enabled and allowed inbound TCP connections on port 22.

The rule initially applied only to the Private network profile.

The active network profile was therefore checked during SSH troubleshooting.

This demonstrated that a service can be installed and listening while still remaining unreachable because of the active Windows Firewall profile.

## 12. Windows Update

Windows Update was run repeatedly until no further updates remained.

The system was restarted when required.

No server roles were installed during this process.

The template remained a clean general-purpose Windows Server base.

## 13. Template Preparation

The machine was renamed to:

```text
WIN-SRV-TMPL
```

The system was then generalized using Sysprep:

```powershell
C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown /mode:vm
```

The options used had the following purposes:

* `/generalize` removed machine-specific information,
* `/oobe` prepared the next boot for initial setup,
* `/shutdown` powered the VM off after completion,
* `/mode:vm` optimized the process for reuse on equivalent virtual hardware.

The VM was not started again after Sysprep.

## 14. Installation Media Removal

After Sysprep completed and the VM shut down, both ISO files were ejected.

The hardware list showed:

```text
CD/DVD Drive ide0: no media
CD/DVD Drive ide2: no media
```

The boot order was changed so that only the main system disk remained:

```text
1. scsi0
```

## 15. Initial Backup

A manual backup was created before converting the VM into a template.

The backup settings were:

```text
Storage:     backup-ssd
Mode:        Snapshot
Compression: ZSTD
```

The backup note was:

```text
Initial Windows Server template backup
```

The backup completed successfully.

## 16. Template Conversion

After the backup completed, VM 110 was converted into a Proxmox template.

The finished template is:

```text
110 (windows-server-gold)
```

The template is not intended to run workloads directly.

Future Windows Server systems will be created as full clones.

## 17. Current Template Status

| Item | Status |
|---|---|
| Windows Server installed | Complete |
| Desktop Experience installed | Complete |
| VirtIO storage driver installed | Complete |
| VirtIO guest tools installed | Complete |
| QEMU guest agent running | Complete |
| OpenSSH installed | Complete |
| OpenSSH service enabled | Complete |
| Windows Firewall rule present | Complete |
| Windows Update completed | Complete |
| Machine renamed | Complete |
| Sysprep completed | Complete |
| Installation media removed | Complete |
| Manual backup created | Complete |
| Converted into Proxmox template | Complete |

## 18. Problems Encountered

1. Windows Setup could not initially see the virtual disk.
2. The VirtIO SCSI driver had to be loaded manually.
3. The OpenSSH service was installed but stopped.
4. Port 22 was not reachable until the service was started.
5. The active Windows network profile had to be considered when checking the firewall rule.
6. The first connection test used the wrong guessed IPv4 address before the actual address was confirmed.

All issues were resolved before the machine was converted into a template.

## 19. Lessons Learned

Windows requires additional VirtIO drivers when using modern paravirtualized Proxmox devices.

Installing the VirtIO guest tools after setup simplifies driver installation and enables the QEMU guest agent.

A service being installed does not mean it is running.

A listening service may still be unreachable when the Windows Firewall rule does not match the active network profile.

Sysprep must be completed before converting the VM into a reusable Windows template.

A clean template should remain free of server roles so it can later be reused for different purposes.

## 20. Next Steps

The next planned task is to create the first real Windows Server system as a full clone:

```text
Source template: windows-server-gold
Target name:     dc01
Clone type:      Full clone
```

The clone will then receive:

* its final hostname,
* a static IP address,
* Active Directory Domain Services,
* DNS,
* and the first lab domain configuration.

The template itself will remain unchanged.
