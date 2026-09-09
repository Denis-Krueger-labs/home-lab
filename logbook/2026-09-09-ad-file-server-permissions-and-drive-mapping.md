# Active Directory File Server, Permissions and Drive Mapping

**Date:** 09 September 2026  
**Environment:** Home Lab / `lab.test`  
**Platform:** Proxmox VE 9.2  
**Domain Controller:** `DC01`  `10.20.0.10`  
**Client:** `CLIENT01`  `10.20.0.20`  
**File Server:** `FS01`  `10.20.0.30`  
**Firewall / Gateway:** `fw01`  `10.20.0.1`

## 1. Goal

Extend the Active Directory lab with a dedicated file server using group-based SMB and NTFS permissions plus automatic drive mapping through Group Policy.

Final access chains:

```text
Nyx
→ GG-Lab-Users
→ DL-FS01-LabShare-RW
→ SMB Change
→ NTFS Modify
```

```text
Rowan Vale
→ GG-Lab-Share-Readers
→ DL-FS01-LabShare-RO
→ SMB Read
→ NTFS Read & Execute
```

## 2. Existing Lab Verification

Before adding the server, `CLIENT01` verified the existing environment:

```powershell
ping 10.20.0.1
ping 10.20.0.10
nslookup lab.test
whoami
```

Confirmed:

```text
fw01 reachable
DC01 reachable
lab.test resolves to 10.20.0.10
LAB\nvalborne logged in
```

## 3. Golden Template

The existing `windows-server-gold` template was used.

Configuration included:

- Windows Server 2025 Standard Evaluation
- Desktop Experience
- UEFI / OVMF
- Secure Boot
- TPM 2.0
- q35
- VirtIO SCSI
- VirtIO network adapter
- QEMU Guest Agent
- OpenSSH Server
- 4 vCPU
- 6 GB RAM
- 80 GB disk
- VirtIO 0.1.285
- fully updated
- generalized with Sysprep

The template remained untouched and a full clone was created.

## 4. FS01 Creation

```text
VM ID: 230
Name: fs01
Source: windows-server-gold
Clone type: Full Clone
```

## 5. Network Correction

The new VM initially appeared on the home LAN:

```text
192.168.178.59
Gateway 192.168.178.1
DNS suffix fritz.box
```

This showed that the VM still had a NIC on `vmbr0`.

A second NIC was temporarily added on `vmbr1`, producing two interfaces:

```text
home LAN: 192.168.178.59
lab LAN:  10.20.0.201
```

The `vmbr0` NIC was removed so `FS01` lived only on the isolated lab network.

## 6. Static Network Configuration

The lab NIC initially received DHCP settings:

```text
IPv4: 10.20.0.203
Gateway: 10.20.0.1
DNS: 10.20.0.1
```

The adapter was identified with:

```powershell
Get-NetIPConfiguration
```

Then DHCP was disabled:

```powershell
Set-NetIPInterface -InterfaceAlias "Ethernet" -Dhcp Disabled
```

Static addressing was configured:

```powershell
New-NetIPAddress `
  -InterfaceAlias "Ethernet" `
  -IPAddress 10.20.0.30 `
  -PrefixLength 24 `
  -DefaultGateway 10.20.0.1
```

DNS was changed to the domain controller:

```powershell
Set-DnsClientServerAddress `
  -InterfaceAlias "Ethernet" `
  -ServerAddresses 10.20.0.10
```

Final settings:

```text
FS01
10.20.0.30/24
Gateway 10.20.0.1
DNS 10.20.0.10
```

## 7. Domain Join

Connectivity and DNS were verified before the join.

`FS01` was joined using:

```powershell
Add-Computer `
  -DomainName "lab.test" `
  -Credential "LAB\Administrator" `
  -Restart
```

After reboot:

```text
Domain: lab.test
Hostname: FS01
```

The computer object was moved into the `Servers` OU.

## 8. File Server Role

The role was installed with:

```powershell
Install-WindowsFeature FS-FileServer -IncludeManagementTools
```

## 9. LabShare Creation

The directory was created:

```powershell
New-Item -ItemType Directory -Path "C:\Shares\LabShare"
```

The share was created with the German-localized Domain Admin group:

```powershell
New-SmbShare `
  -Name "LabShare" `
  -Path "C:\Shares\LabShare" `
  -FullAccess "LAB\Domänen-Admins"
```

## 10. Read/Write Group Model

Created domain-local security group:

```text
DL-FS01-LabShare-RW
```

The existing global group:

```text
GG-Lab-Users
```

was nested inside it.

Result:

```text
Nyx
→ GG-Lab-Users
→ DL-FS01-LabShare-RW
```

This follows an AGDLP-style structure:

```text
Accounts
→ Global Groups
→ Domain Local Groups
→ Permissions
```

## 11. SMB Read/Write Permission

```powershell
Grant-SmbShareAccess `
  -Name "LabShare" `
  -AccountName "LAB\DL-FS01-LabShare-RW" `
  -AccessRight Change `
  -Force
```

Verified:

```text
LAB\Domänen-Admins         Full
LAB\DL-FS01-LabShare-RW   Change
```

## 12. NTFS Permission Cleanup

Initial ACL inspection showed inherited entries for built-in Users.

Inheritance was removed:

```powershell
icacls "C:\Shares\LabShare" /inheritance:r
```

The intended ACL was set:

```powershell
icacls "C:\Shares\LabShare" /grant:r `
  "NT-AUTORITÄT\SYSTEM:(OI)(CI)(F)" `
  "VORDEFINIERT\Administratoren:(OI)(CI)(F)" `
  "LAB\Domänen-Admins:(OI)(CI)(F)" `
  "LAB\DL-FS01-LabShare-RW:(OI)(CI)(M)"
```

## 13. Read/Write Test

From `CLIENT01` as Nyx:

```text
\\FS01\LabShare
```

Verified:

- open share
- create folder
- create file
- rename
- delete

## 14. GPO Drive Mapping

A new GPO was created and linked to `Lab Users`:

```text
GPO-Lab-Users-DriveMap
```

Configured under:

```text
User Configuration
→ Preferences
→ Windows Settings
→ Drive Maps
```

Settings:

```text
Action: Create
Location: \\FS01\LabShare
Reconnect: enabled
Label: LabShare
Drive letter: L:
```

On `CLIENT01`:

```powershell
gpupdate /force
```

After sign-out/sign-in, the share appeared as:

```text
L: LabShare
```

## 15. Read-Only Permission Model

Created:

```text
DL-FS01-LabShare-RO
```

as Domain Local / Security.

Created:

```text
GG-Lab-Share-Readers
```

as Global / Security.

Nested:

```text
GG-Lab-Share-Readers
→ DL-FS01-LabShare-RO
```

Created test user:

```text
Rowan Vale
rvale
```

and added the user to:

```text
GG-Lab-Share-Readers
```

Final chain:

```text
Rowan Vale
→ GG-Lab-Share-Readers
→ DL-FS01-LabShare-RO
```

## 16. Read-Only SMB and NTFS Permissions

SMB:

```powershell
Grant-SmbShareAccess `
  -Name "LabShare" `
  -AccountName "LAB\DL-FS01-LabShare-RO" `
  -AccessRight Read `
  -Force
```

NTFS:

```powershell
icacls "C:\Shares\LabShare" /grant `
  "LAB\DL-FS01-LabShare-RO:(OI)(CI)(RX)"
```

Final SMB permissions:

```text
LAB\Domänen-Admins         Full
LAB\DL-FS01-LabShare-RW   Change
LAB\DL-FS01-LabShare-RO   Read
```

Final NTFS permissions:

```text
LAB\DL-FS01-LabShare-RO      Read & Execute
LAB\DL-FS01-LabShare-RW      Modify
LAB\Domänen-Admins            Full
VORDEFINIERT\Administratoren  Full
NT-AUTORITÄT\SYSTEM           Full
```

## 17. Read-Only Functional Test

On `CLIENT01`, `LAB\rvale` accessed:

```text
\\FS01\LabShare
```

Verified:

```text
Can browse folders
Can open existing files
Cannot create files
Cannot create folders
Cannot rename
Cannot delete
```

## 18. Final Environment

| System | Role | Address |
|---|---|---|
| `fw01` | OPNsense firewall / gateway | `10.20.0.1` |
| `DC01` | AD DS / DNS | `10.20.0.10` |
| `CLIENT01` | Domain workstation | `10.20.0.20` |
| `FS01` | Domain file server | `10.20.0.30` |

Relevant groups:

```text
GG-Lab-Users
DL-FS01-LabShare-RW
GG-Lab-Share-Readers
DL-FS01-LabShare-RO
```

Relevant GPOs:

```text
GPO-Workstations-Baseline
GPO-Lab-Users-Baseline
GPO-Lab-Users-DriveMap
```

## 19. Problems Encountered

1. `FS01` initially inherited the wrong Proxmox bridge.
2. A second NIC was briefly added instead of replacing the first.
3. DHCP initially pointed DNS to OPNsense rather than `DC01`.
4. German Windows localized `Domain Admins` as `Domänen-Admins`.
5. `LabShare` was once mistyped as `LabSahre`.
6. `LabShare` was once mistyped as `LabShares`.
7. Group Policy navigation was unnecessarily nested.
8. Administration required repeated jumping between `DC01`, `FS01`, and `CLIENT01`.

## 20. Lessons Learned

A golden template should remain unchanged and be used only for clones.

Domain members should use the domain controller as DNS.

SMB and NTFS permissions are separate security layers and both must be configured.

Users should normally receive resource access through nested security groups, not direct ACL assignments.

AGDLP-style nesting makes permission intent easier to understand and maintain.

Permissions should always be tested with real accounts.

GPO Preferences can automate SMB drive mapping for domain users.

A dedicated admin workstation and remote-management tooling would reduce repeated VM hopping.

And finally:

```text
Being a typo gremlin is bad for Windows sysadminning.
```

Small naming mistakes can produce errors that look significantly more serious than the actual problem.

## 21. Next Steps

The next logical AD project is centralized administration:

```text
Dedicated admin workstation
RSAT
PowerShell Remoting
Server Manager remote administration
Remote Event Viewer
Remote Services
Separate administrative accounts
Least-privilege admin workflows
```

Potential later file-server work:

```text
File Server Resource Manager
Quotas
Shadow Copies
Access-Based Enumeration
DFS
Audit policies
File-access logging
Backup and restore testing
```

This session successfully extended the lab from a basic Active Directory environment into a working domain file-service environment with group-based read/write and read-only access plus automatic drive mapping.
