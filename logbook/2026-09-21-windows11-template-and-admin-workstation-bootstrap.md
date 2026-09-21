# Windows 11 Gold Template and Administrative Workstation Bootstrap

**Date:** 21 September 2026  
**Environment:** Home Lab / `lab.test`  
**Platform:** Proxmox VE 9.2  
**Domain Controller:** `DC01` - `10.20.0.10`  
**Administrative Workstation:** `ADMIN01` - `10.20.0.40`  
**Windows 11 Template Preparation VM:** `windows11-gold-prep` - VM `120`  
**Firewall / Gateway:** `fw01` - `10.20.0.1`

## 1. Goal

Continue the Active Directory lab after the file server milestone by introducing a dedicated administrative workstation and preparing a reusable Windows 11 Enterprise gold template.

The administrative model is being built around separation between normal and privileged identities:

```text
Normal workstation / normal user
        |
        | no administrative privileges
        v
CLIENT01 / Nyx

Dedicated administrative workstation
        |
        | privileged administration only
        v
ADMIN01
```

The intended next stage is to create a separate administrative identity, install RSAT, and use `ADMIN01` for Active Directory and server administration instead of performing routine administration directly on `DC01`.

## 2. Windows 11 Enterprise Base Installation

A fresh Windows 11 Enterprise Evaluation VM was created rather than modifying the existing domain client.

Initial VM:

```text
VM ID: 240
Name: admin01
OS: Windows 11 Enterprise Evaluation 25H2
Language: German
Network: vmbr1
```

Virtual hardware:

```text
Machine type: q35
Firmware: OVMF / UEFI
Secure Boot: enabled through pre-enrolled keys
TPM: 2.0
CPU: 2 cores
RAM: 4 GB
Disk: 64 GB
Controller: VirtIO SCSI Single
Network adapter: VirtIO
```

The VM was connected only to the isolated lab bridge:

```text
vmbr1
```

This keeps the administrative workstation inside the lab network rather than placing it directly on the home LAN.

## 3. Windows Installation and VirtIO Integration

Windows 11 Enterprise Evaluation was installed from ISO.

During initial setup, Windows did not yet have a working VirtIO network driver. The VirtIO driver ISO was therefore attached and the guest tools were installed.

Installed:

```text
virtio-win-guest-tools.exe
VirtIO drivers 0.1.285
QEMU Guest Agent
```

The QEMU Guest Agent service was verified as running.

A local installation account was used:

```text
localadmin
```

No Microsoft account was required for the template preparation process.

## 4. Windows Update Baseline

The fresh installation was fully updated before being used as the basis for the gold image.

Updates included the current September 2026 Windows security and cumulative updates.

The goal was to avoid creating a template that would immediately require a large update cycle after every clone.

## 5. Gold Template Preparation Clone

Before turning `ADMIN01` into a domain administration workstation, a full clone was created from the clean Windows 11 installation.

```text
Source VM: 240 admin01
Clone type: Full Clone
Clone VM ID: 120
Name: windows11-gold-prep
```

This preserved the original VM for continued administrative workstation configuration while allowing VM `120` to be generalized independently.

The Windows installation ISO and VirtIO ISO were detached from VM `120` before Sysprep.

The intended final state is:

```text
VM 120
windows11-gold-prep
        |
        | Sysprep /generalize
        v
windows11-gold
        |
        v
Proxmox Template
```

## 6. Sysprep Attempt 1 - Reserved Storage Blocker

The first Sysprep attempt used:

```text
System Cleanup Action:
Enter System Out-of-Box Experience (OOBE)

Generalize:
Enabled

Shutdown Options:
Shutdown
```

Sysprep failed.

The error log showed:

```text
SYSPRP Sysprep_Clean_Validate_Opk:
Audit mode cannot be turned on if reserved storage is in use.

0x800F0975
```

Reserved Storage was confirmed as enabled.

The package servicing state was checked for pending packages:

```powershell
Get-WindowsPackage -Online |
Where-Object PackageState -Match "Pending" |
Select-Object PackageName, PackageState
```

No pending packages were returned.

Reserved Storage was then successfully disabled:

```powershell
DISM.exe /Online /Set-ReservedStorageState /State:Disabled
```

This removed the first Sysprep blocker.

## 7. Sysprep Attempt 2 - German Language Experience Pack

The second attempt progressed further but failed during AppX validation.

The new error was:

```text
Microsoft.LanguageExperiencePackde-DE
was installed for a user, but not provisioned for all users.

0x80073cf2
```

The affected package was:

```text
Microsoft.LanguageExperiencePackde-DE_26100.169.270.0_neutral__8wekyb3d8bbwe
```

The problem was an inconsistent AppX state: the German Language Experience Pack was registered for a user but was not provisioned consistently for the entire image.

The package was first inspected with:

```powershell
Get-AppxPackage -AllUsers |
Where-Object { $_.Name -like "*LanguageExperiencePack*DE*" } |
Select-Object Name, PackageFullName, PackageUserInformation
```

A provisioning check returned no matching provisioned package:

```powershell
Get-AppxProvisionedPackage -Online |
Where-Object { $_.DisplayName -eq "Microsoft.LanguageExperiencePackde-DE" } |
Select-Object DisplayName, PackageName
```

Removing the package only from the currently logged-in user was not enough. Sysprep still detected the package registered for another user profile.

The final cleanup therefore removed the package registration for all users:

```powershell
Get-AppxPackage -AllUsers -Name "Microsoft.LanguageExperiencePackde-DE" |
Remove-AppxPackage -AllUsers
```

Verification:

```powershell
Get-AppxPackage -AllUsers -Name "Microsoft.LanguageExperiencePackde-DE"
```

returned no package.

After this cleanup, Sysprep finally began the generalization process successfully.

At the time of this report, VM `120` is completing Sysprep in the background. Once it shuts itself down successfully, it must not be booted again before conversion into the Proxmox template.

## 8. ADMIN01 Static Network Configuration

Work continued on VM `240` while the template preparation VM was running Sysprep.

The final static configuration for the administrative workstation is:

```text
Hostname: ADMIN01
IPv4: 10.20.0.40/24
Gateway: 10.20.0.1
DNS: 10.20.0.10
Network: vmbr1
```

The domain controller remains the DNS server so Active Directory DNS records are resolved correctly.

## 9. Administrative Workstation Rename

The original automatically generated Windows hostname was replaced with the intended administrative workstation name:

```powershell
Rename-Computer -NewName "ADMIN01" -Restart
```

After reboot:

```powershell
hostname
```

returned:

```text
ADMIN01
```

## 10. Domain Connectivity Verification

Before joining the domain, connectivity and DNS were checked from `ADMIN01`.

```powershell
ping 10.20.0.10
nslookup lab.test
nslookup dc01.lab.test
```

All tests completed successfully.

This confirmed:

```text
ADMIN01 can reach DC01
lab.test resolves through DC01
dc01.lab.test resolves correctly
```

## 11. Domain Join

`ADMIN01` was joined to the existing Active Directory domain:

```powershell
Add-Computer `
  -DomainName "lab.test" `
  -Credential "LAB\Administrator" `
  -Restart
```

After reboot, domain membership was verified with:

```powershell
(Get-CimInstance Win32_ComputerSystem).Domain
hostname
```

Confirmed state:

```text
Domain: lab.test
Hostname: ADMIN01
```

## 12. Administrative Workstation OU

A dedicated Organizational Unit was created:

```text
lab.test
└── Admin Workstations
```

Protection from accidental deletion was left enabled.

The `ADMIN01` computer object was moved from the default `Computers` container into the new OU.

Current placement:

```text
lab.test
└── Admin Workstations
    └── ADMIN01
```

This provides a dedicated policy scope for privileged workstations and prevents administrative systems from being mixed with normal workstation objects.

## 13. VM Tag Organization

The Proxmox VM tags were cleaned up to make roles and security context easier to identify from the management interface.

The general tag order now follows:

```text
[STATE / RISK]
→ [PRIMARY ROLE]
→ [FUNCTION / ENVIRONMENT]
→ [PLATFORM]
```

Examples include:

```text
ADMIN01
privileged / admin / rsat / windows

DC01
identity / ad / dns

FS01
file-server / domain-member / windows

CLIENT01
workstation / domain-member / windows

copyfail-vuln
vulnerable / copyfail / security-lab / ubuntu

copyfail01
mitigated / copyfail / security-lab / ubuntu
```

The color overrides make high-risk, privileged, infrastructure, and template systems easier to distinguish visually.

## 14. Problems Encountered

### 14.1 Sysprep and Reserved Storage

Sysprep refused to generalize the Windows image while Reserved Storage was considered in use.

The useful lesson was that Sysprep depends on Windows servicing state, not only the visible update state in Settings.

### 14.2 AppX State Is Per User

Removing the German Language Experience Pack from the current account did not resolve the Sysprep error.

The important distinction was:

```powershell
Get-AppxPackage
```

checks the current user, while:

```powershell
Get-AppxPackage -AllUsers
```

reveals registrations belonging to other user profiles.

For Sysprep, the all-user state matters.

### 14.3 Do Not Treat AppX Cleanup as a Carpet-Bombing Exercise

Only the package explicitly identified in the Sysprep error log was removed.

No broad AppX removal script was used.

This kept the troubleshooting controlled and avoided unnecessarily damaging the Windows image.

### 14.4 Tiny Typo Gremlin Incident

While configuring the workstation, `FS01` was briefly mistaken for the target system during networking work.

The mistake was caught before it became a configuration problem.

Being a typo gremlin remains a recurring occupational hazard of Windows sysadminning.

## 15. Current Architecture

```text
                          Home LAN
                      192.168.178.0/24
                              |
                              |
                         Proxmox VE
                              |
                            vmbr1
                              |
                         +----+----+
                         | fw01    |
                         | OPNsense|
                         |10.20.0.1|
                         +----+----+
                              |
                         10.20.0.0/24
                              |
          +-------------------+-------------------+
          |                   |                   |
       DC01                FS01               CLIENT01
    10.20.0.10          10.20.0.30          10.20.0.20
   AD DS / DNS          File Server          User Client
          |
          |
       ADMIN01
    10.20.0.40
 Dedicated privileged
 administration station
```

## 16. Current State

Completed:

- fresh Windows 11 Enterprise installation
- VirtIO drivers installed
- QEMU Guest Agent installed and verified
- Windows fully updated
- full clone created for gold template preparation
- installation media detached from template-prep VM
- Reserved Storage Sysprep blocker identified and resolved
- Language Experience Pack Sysprep blocker identified and resolved
- Sysprep generalization started successfully
- `ADMIN01` configured with static addressing
- `ADMIN01` renamed
- domain connectivity and DNS verified
- `ADMIN01` joined to `lab.test`
- `Admin Workstations` OU created
- `ADMIN01` moved into the dedicated OU
- Proxmox tagging scheme improved

In progress:

- completion of Sysprep on VM `120`

Not yet completed:

- convert VM `120` to `windows11-gold` template
- create `Admin Accounts` OU
- create separate privileged administrator account
- define minimum required administrative group memberships
- install RSAT on `ADMIN01`
- administer ADUC and GPMC from `ADMIN01`
- configure PowerShell Remoting to `DC01` and `FS01`
- test remote Event Viewer
- test remote Services management
- confirm normal user `Nyx` cannot perform administrative actions
- confirm the dedicated admin identity can perform delegated administration
- create final snapshot / backup

## 17. Lessons Learned

1. A gold image should be generalized before it becomes domain-specific.
2. Windows servicing state can block Sysprep even when Windows Update appears finished.
3. AppX packages can exist in different states for different users.
4. Sysprep errors should be solved from the exact package named in the log rather than with aggressive cleanup scripts.
5. A separate administrative workstation provides a cleaner foundation for least-privilege administration.
6. Organizational Units should reflect security and policy boundaries, not merely device type.
7. DNS verification before a domain join saves a significant amount of troubleshooting.
8. Building the Windows 11 template now prevents repeating this entire two-day Sysprep dungeon for every future workstation.

## 18. Next Step

The next Active Directory task is:

```text
Create Admin Accounts OU
        |
        v
Create dedicated privileged account
        |
        v
Delegate only required privileges
        |
        v
Install RSAT on ADMIN01
        |
        v
Move routine administration away from DC01
```

The normal `Nyx` account will remain unprivileged.

Administrative work will be performed through a separate identity from the dedicated `ADMIN01` workstation.
