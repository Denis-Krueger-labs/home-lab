# Windows 11 Enterprise Client and Domain Join

**Date:** 28 July 2026  
**System:** Dell OptiPlex 5070 Micro  
**Platform:** Proxmox VE 9.2  
**Virtual machine:** VM 220, `client01`  
**Goal:** Create the first Windows 11 Enterprise client, connect it to the isolated lab network, and join it to the `lab.test` Active Directory domain.

## 1. Starting Point

The following infrastructure was already available before creating the client:

```text
Proxmox node: pve
Management IP: <PVE_MANAGEMENT_IP>
Internal bridge: vmbr1
OPNsense firewall: fw01
OPNsense LAN: <LAB_GATEWAY>/24
Domain controller: DC01
Domain controller IP: <DC_IP>
Active Directory domain: lab.test
NetBIOS domain: LAB
```

The isolated network used:

```text
<LAB_SUBNET>
```

The first Windows 11 client was intended to become a domain-joined workstation inside this network.

## 2. Installation Media

The following ISO files were available in Proxmox:

```text
Windows 11 Enterprise Evaluation 25H2, German
virtio-win-0.1.285.iso
```

The Windows 11 ISO filename was:

```text
26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_de-de.iso
```

The Windows 11 Enterprise Evaluation edition was selected because it supports Active Directory domain join and can be used for lab evaluation without purchasing a permanent license.

The VirtIO ISO provided the storage, network, and guest-agent drivers required for the Proxmox virtual hardware.

## 3. Virtual Machine Creation

A new virtual machine was created with:

```text
VM ID: 220
Name: client01
```

The VM was designed as the first standard workstation in the `lab.test` domain.

## 4. Virtual Hardware Configuration

| Setting | Value |
|---|---|
| Machine type | q35 |
| Firmware | OVMF, UEFI |
| EFI disk | Enabled |
| Secure Boot keys | Pre-enrolled |
| TPM | Version 2.0 |
| SCSI controller | VirtIO SCSI single |
| CPU | 2 vCPUs |
| CPU type | x86-64-v2-AES |
| Memory | 4 GB |
| Main disk | 64 GB |
| Disk storage | local-lvm |
| Disk bus | SCSI |
| Discard | Enabled |
| IO thread | Enabled |
| SSD emulation | Enabled |
| Network adapter | VirtIO |
| Network bridge | vmbr1 |
| Proxmox firewall flag | Enabled |
| Operating system type | Windows 11 |

The VM was attached directly to the isolated internal bridge:

```text
vmbr1
```

This placed it behind OPNsense and inside the `<LAB_SUBNET>` lab subnet.

## 5. Installation Media Configuration

The VM used two virtual CD/DVD drives:

```text
ide2: Windows 11 Enterprise Evaluation ISO
ide0: virtio-win-0.1.285.iso
```

The boot order was configured as:

```text
1. ide2
2. scsi0
```

The VirtIO ISO was not included in the boot order.

## 6. Windows 11 Installation

The VM was started and manually booted from:

```text
UEFI QEMU DVD-ROM
```

Windows 11 Enterprise Evaluation was installed in German.

The installation used the normal graphical Windows setup process.

## 7. VirtIO Network Driver During OOBE

During the initial Windows setup, no network adapter was detected.

The VirtIO network driver was installed from:

```text
NetKVM
└── w11
    └── amd64
```

After the driver was loaded, Windows detected the Red Hat VirtIO Ethernet Adapter.

The VM then received network access through OPNsense.

## 8. Local Account Setup

Windows attempted to request a Microsoft business, school, or university account during OOBE.

This was skipped using the domain-join or sign-in-options path.

A temporary local administrator account was created:

```text
localadmin
```

This account was used only to complete the initial setup and prepare the machine for the real Active Directory domain join.

No Microsoft account or university account was connected.

## 9. VirtIO Guest Tools

After reaching the desktop, the full VirtIO guest tools package was installed from:

```text
virtio-win-guest-tools.exe
```

This installed the remaining virtual hardware drivers and the QEMU guest agent.

The default installation options were used.

## 10. Computer Rename

The workstation was renamed to:

```text
CLIENT01
```

The machine was restarted after the rename.

The final hostname was verified with:

```powershell
hostname
```

The result was:

```text
CLIENT01
```

## 11. Static Network Configuration

The Windows client was changed from DHCP to a static IPv4 configuration.

The final settings were:

```text
IP address:      <CLIENT_IP>
Subnet mask:     255.255.255.0
Default gateway: <LAB_GATEWAY>
Preferred DNS:   <DC_IP>
Alternate DNS:   none
```

The DNS server points directly to the domain controller.

This is required because Active Directory clients must use the AD-integrated DNS service to locate domain controllers and domain services.

## 12. Network Adapter Verification

Windows detected the network adapter as:

```text
Red Hat VirtIO Ethernet Adapter
```

The adapter showed:

```text
IPv4 address: <CLIENT_IP>
Gateway:      <LAB_GATEWAY>
DNS server:   <DC_IP>
```

Windows displayed the virtual link speed as:

```text
10/10 Gbps
```

This is the reported virtual adapter speed and does not represent the physical Ethernet speed of the Proxmox host.

## 13. Initial Connectivity Issue

The first connectivity test to the domain controller failed:

```powershell
ping <DC_IP>
```

The client reported:

```text
Destination host unreachable
```

The ARP table contained an entry for OPNsense at `<LAB_GATEWAY>`, but no entry for `<DC_IP>`.

The cause was that `DC01` was powered off.

After starting `DC01` and waiting for Active Directory and DNS services to become available, name resolution succeeded.

This demonstrated that the domain controller must be online for:

* DNS resolution,
* domain discovery,
* domain join,
* authentication,
* and Group Policy processing.

## 14. DNS Verification

The client successfully resolved the domain controller:

```powershell
Resolve-DnsName dc01.lab.test
```

The result was:

```text
dc01.lab.test → <DC_IP>
```

This confirmed that:

* the client was using `<DC_IP>` as its DNS server,
* the `lab.test` zone was available,
* and DC01 was reachable.

## 15. Domain Join

The classic System Properties dialog was opened with:

```text
sysdm.cpl
```

The computer was joined to:

```text
lab.test
```

The credentials used were:

```text
LAB\Administrator
```

Windows successfully displayed the welcome message for the `lab.test` domain.

The machine was then restarted.

## 16. Domain Login

After rebooting, the workstation was logged into using the domain Administrator account.

The logged-in identity was verified with:

```powershell
whoami
```

The result was:

```text
lab\administrator
```

The domain environment variable was checked with:

```powershell
$env:USERDOMAIN
```

The result was:

```text
LAB
```

## 17. Secure Channel Verification

The secure channel between the workstation and the domain was tested with:

```powershell
Test-ComputerSecureChannel
```

The result was:

```text
True
```

This confirmed that the computer account trust relationship with the domain was healthy.

## 18. Group Policy Verification

Group Policy processing was checked with:

```powershell
gpresult /r
```

The output confirmed:

```text
Computer:
CN=CLIENT01,CN=Computers,DC=lab,DC=test
```

The Group Policy source was:

```text
DC01.lab.test
```

The applied computer policy was:

```text
Default Domain Policy
```

The user section did not yet show a custom user policy because no separate user-targeted Group Policy Objects had been created.

## 19. Domain Membership Verification

| Check | Result |
|---|---|
| Hostname | CLIENT01 |
| Domain | lab.test |
| Logged-in account | LAB\Administrator |
| DNS server | <DC_IP> |
| DC resolution | Successful |
| Secure channel | True |
| Computer object | Present in CN=Computers |
| Group Policy source | DC01.lab.test |
| Default Domain Policy | Applied |

## 20. Current Client Status

| Item | Status |
|---|---|
| Windows 11 Enterprise installed | Complete |
| UEFI and Secure Boot configured | Complete |
| TPM 2.0 configured | Complete |
| VirtIO storage configuration | Complete |
| VirtIO network driver installed | Complete |
| VirtIO guest tools installed | Complete |
| QEMU guest agent installed | Complete |
| Local setup account created | Complete |
| Computer renamed to CLIENT01 | Complete |
| Static IPv4 configured | Complete |
| DNS configured to DC01 | Complete |
| Domain controller resolution verified | Complete |
| Joined to lab.test | Complete |
| Domain login verified | Complete |
| Secure channel verified | Complete |
| Group Policy processing verified | Complete |

## 21. Problems Encountered

1. Windows 11 did not initially detect the VirtIO network adapter.
2. The NetKVM driver had to be loaded manually during OOBE.
3. Windows attempted to force a Microsoft business, school, or university account during setup.
4. A temporary local administrator account had to be created instead.
5. The 64 GB system disk was initially almost configured on the wrong bus and was corrected to SCSI.
6. The first ping to DC01 failed because the domain controller was powered off.
7. DNS and domain join could not work until DC01 was online.
8. Windows exposed several unnecessary setup and update screens before the desktop became usable.

All issues were resolved before the workstation was joined to the domain.

## 22. Lessons Learned

Windows 11 requires TPM 2.0 and UEFI for a normal supported virtual installation.

VirtIO drivers must be available during installation when Proxmox presents paravirtualized devices.

A Windows client should use the domain controller as its DNS server before joining Active Directory.

The default gateway remains OPNsense, while DNS points to DC01.

The domain controller must be online for domain discovery and authentication.

A successful DNS lookup does not only test name resolution; it also confirms that the client can locate the AD DNS infrastructure.

`Test-ComputerSecureChannel` provides a quick way to verify the workstation trust relationship.

`gpresult /r` confirms which domain controller processed policy and which Group Policy Objects were applied.

The built-in domain Administrator account should not be used as a normal daily user.

## 23. Final Topology

```text
Home network
<MANAGEMENT_SUBNET>
        |
        | vmbr0
        |
fw01 WAN
<OPNSENSE_WAN_IP>
        |
OPNsense
        |
fw01 LAN
<LAB_GATEWAY>
        |
        | vmbr1
        |
        ├── DC01
        |   <DC_IP>
        |   dc01.lab.test
        |   AD DS + DNS
        |
        └── CLIENT01
            <CLIENT_IP>
            client01.lab.test
            Windows 11 Enterprise
```

## 24. Next Steps

The next task is to create a basic Active Directory structure.

Planned organizational units:

```text
OU=Servers
OU=Workstations
OU=Users
OU=Groups
OU=Service Accounts
```

The existing systems will then be moved to:

```text
DC01     → OU=Servers
CLIENT01 → OU=Workstations
```

The next session will also include:

* creating a normal test user,
* creating security groups,
* assigning group membership,
* testing a normal domain-user login,
* creating the first custom Group Policy Object,
* and confirming that the policy applies to CLIENT01.

The built-in domain Administrator account will remain reserved for administrative work.
