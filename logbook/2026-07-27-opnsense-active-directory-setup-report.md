# OPNsense, Isolated Lab Network and Active Directory Setup

**Date:** 27 July 2026  
**System:** Dell OptiPlex 5070 Micro  
**Platform:** Proxmox VE 9.2  
**Virtual machines:** VM 210, `fw01`; VM 200, `dc01`  
**Goal:** Create an isolated routed lab network behind OPNsense and deploy the first Windows Server 2025 domain controller.

## 1. Starting Point

The Proxmox host, backup storage, Debian template, Windows Server 2025 template, and initial Windows Server clone had already been prepared.

The existing Proxmox management network used:

```text
Bridge:  vmbr0
Network: <MANAGEMENT_SUBNET>
Node IP: <PVE_MANAGEMENT_IP>
Gateway: <HOME_GATEWAY>
```

The Windows Server clone `dc01` initially used `vmbr0` and was connected directly to the normal home network.

The goal of this session was to create a separate internal lab network and place the Windows Server system behind an OPNsense firewall.

## 2. Isolated Proxmox Bridge

A second Proxmox bridge was created:

```text
Bridge: vmbr1
```

The bridge was configured with:

| Setting | Value |
|---|---|
| IPv4 | None |
| IPv6 | None |
| Bridge ports | None |
| Autostart | Enabled |
| VLAN aware | Enabled |
| Comment | Isolated home-lab network |

No physical network interface was attached.

This made `vmbr1` an internal virtual network that exists only inside Proxmox.

The bridge was activated and verified with:

```bash
ip link show vmbr1
```

The result showed:

```text
vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP>
state UP
```

## 3. OPNsense Virtual Machine Creation

A new OPNsense firewall VM was created.

```text
VM ID: 210
Name: fw01
```

The VM was configured with:

| Setting | Value |
|---|---|
| Machine type | q35 |
| Firmware | OVMF, UEFI |
| EFI disk | Enabled |
| CPU | 2 vCPUs |
| Memory | 4 GB |
| Main disk | 16 GB |
| Disk bus | SCSI |
| Discard | Enabled |
| IO thread | Enabled |
| SSD emulation | Enabled |
| Network adapter model | VirtIO |
| Proxmox firewall flag | Disabled on both NICs |

The VM used two network adapters:

```text
net0: vmbr0
net1: vmbr1
```

The intended roles were:

```text
net0 → WAN
net1 → LAN
```

## 4. OPNsense Installation Media

The following ISO was uploaded to the Proxmox local ISO storage:

```text
OPNsense-26.7-dvd-amd64.iso
```

The ISO was attached to:

```text
ide2
```

The initial boot order was:

```text
1. ide2
2. scsi0
```

## 5. OPNsense Installation

The OPNsense installer was started from the ISO.

The default US keyboard layout was used during installation.

The selected installation mode was:

```text
Install (UFS)
```

UFS was chosen because the firewall uses a single small virtual disk and does not require ZFS features such as redundancy or storage snapshots.

The installer warned that the original 2 GB memory allocation was too low and required at least 3 GB to copy the live system.

The VM was therefore shut down and increased to:

```text
Memory: 4096 MB
Ballooning: disabled
```

The installation then completed successfully.

After installation:

```text
ide2: no media
Boot order: scsi0
```

## 6. OPNsense Interface Assignment

After the first boot from disk, the VirtIO interfaces were assigned as:

```text
WAN: vtnet0
LAN: vtnet1
```

The first assignment attempt had WAN and LAN reversed.

This was corrected before continuing with the final interface configuration.

## 7. OPNsense WAN Configuration

The WAN interface was connected to:

```text
vtnet0 → vmbr0
```

The WAN interface used DHCP and received:

```text
<OPNSENSE_WAN_IP>/24
```

This placed the OPNsense WAN interface on the normal home network.

Because the WAN itself uses a private RFC1918 network, the following option was disabled:

```text
Block RFC1918 Private Networks
```

The following option remained enabled:

```text
Block bogon networks
```

The remaining WAN settings were left at their defaults.

## 8. OPNsense LAN Configuration

The LAN interface was connected to:

```text
vtnet1 → vmbr1
```

The LAN interface was configured with:

```text
IP address: <LAB_GATEWAY>
Subnet:    /24
Gateway:   none
```

IPv6 configuration was not added manually.

The final interface state was:

```text
LAN: <LAB_GATEWAY>/24
WAN: <OPNSENSE_WAN_IP>/24
```

## 9. OPNsense DHCP Configuration

The DHCP server was enabled on the LAN interface.

The DHCP range was configured as:

```text
<LAB_DHCP_START>
to
<LAB_DHCP_END>
```

The lower part of the subnet remains available for statically assigned infrastructure systems.

The planned addressing scheme is:

| Address | System |
|---|---|
| <LAB_GATEWAY> | fw01 |
| <DC_IP> | dc01 |
| <CLIENT_IP> | client01 |
| <LAB_HOST_01_IP> | docker01 |
| <LAB_HOST_02_IP> | monitor01 |

## 10. OPNsense Initial Configuration Wizard

The OPNsense setup wizard was completed with:

```text
Hostname: fw01
Domain:   internal
Language: English
Timezone: Europe/Berlin
```

The DNS server fields were left empty.

The following options were enabled:

```text
Override DNS
Enable Resolver
Automatic DHCP/DNS registration
```

The following options were disabled:

```text
Optimize for Multi-WAN
Optimize for IPsec
DNSSEC support
Harden DNSSEC data
```

Unbound remained enabled as the DNS resolver.

The web interface remained on HTTPS.

## 11. Moving DC01 to the Isolated Network

The Windows Server VM `dc01` was shut down.

Its Proxmox network adapter was changed from:

```text
vmbr0
```

to:

```text
vmbr1
```

After booting, the server received an address from the OPNsense DHCP server.

The OPNsense web interface was then reached from `dc01` at:

```text
https://<LAB_GATEWAY>
```

This confirmed that `dc01` was connected to the isolated network.

## 12. Initial Network Verification

The following tests were run from `dc01`:

```powershell
ping <LAB_GATEWAY>
ping 1.1.1.1
nslookup example.com
```

All tests completed successfully.

This confirmed:

* connectivity to the OPNsense LAN interface,
* outbound routing,
* NAT,
* internet access,
* and DNS resolution.

The working traffic path was:

```text
dc01
→ vmbr1
→ OPNsense LAN
→ OPNsense WAN
→ FRITZ!Box
→ Internet
```

## 13. Static IP Configuration for DC01

The Windows Server network adapter was changed from DHCP to a static configuration.

The final settings were:

```text
IP address:      <DC_IP>
Subnet mask:     255.255.255.0
Default gateway: <LAB_GATEWAY>
Preferred DNS:   <LAB_GATEWAY>
```

The configuration was verified with:

```powershell
ipconfig
ping <LAB_GATEWAY>
ping 1.1.1.1
nslookup example.com
```

All tests remained successful.

## 14. Active Directory Domain Services Installation

The following server role was installed:

```text
Active Directory Domain Services
```

Windows automatically added the required tools and features, including:

* Group Policy Management,
* Remote Server Administration Tools,
* AD DS tools,
* Active Directory Administrative Center,
* Active Directory PowerShell module,
* and AD DS command-line tools.

No automatic restart was selected during the role installation.

The role installation completed successfully.

## 15. Domain Controller Promotion

The server was promoted to the first domain controller in a new forest.

The selected deployment type was:

```text
Add a new forest
```

The new forest root domain was:

```text
lab.test
```

The NetBIOS domain name was:

```text
LAB
```

The resulting domain controller name is:

```text
DC01.lab.test
```

## 16. Domain Controller Options

The domain controller was configured with:

| Setting | Value |
|---|---|
| Forest functional level | Windows Server 2025 |
| Domain functional level | Windows Server 2025 |
| DNS Server | Enabled |
| Global Catalog | Enabled |
| Read-only domain controller | Disabled |

A Directory Services Restore Mode password was configured.

The DSRM password is stored separately and is not included in this report.

## 17. DNS Delegation Warning

During domain controller promotion, Windows displayed a warning that a DNS delegation could not be created.

This occurred because no authoritative parent DNS zone exists for:

```text
lab.test
```

The warning was expected for the first domain controller in a new standalone forest.

No DNS delegation was created.

## 18. Active Directory Paths

The default Active Directory storage paths were retained:

```text
Database folder: C:\Windows\NTDS
Log files folder: C:\Windows\NTDS
SYSVOL folder:    C:\Windows\SYSVOL
```

Separate storage volumes were not required for this small single-domain-controller lab.

## 19. Prerequisite Check and Promotion

The Active Directory prerequisite check completed successfully.

The only remaining message was the expected DNS delegation warning.

The server was promoted and rebooted automatically.

After rebooting, the domain Administrator account was used:

```text
LAB\Administrator
```

## 20. Active Directory Verification

The logged-in account was verified with:

```powershell
whoami
```

The result was:

```text
lab\administrator
```

The domain was checked using:

```powershell
Get-ADDomain
Get-ADForest
```

The results confirmed:

```text
DNS root:     lab.test
NetBIOS name: LAB
Forest:       lab.test
Domain mode:  Windows2025Domain
Forest mode:  Windows2025Forest
```

The domain controller holds all FSMO roles because it is currently the only domain controller.

Important role holders include:

```text
PDC Emulator:        DC01.lab.test
RID Master:          DC01.lab.test
Infrastructure Master: DC01.lab.test
Schema Master:       DC01.lab.test
Domain Naming Master: DC01.lab.test
```

## 21. DNS Configuration After Promotion

After promotion, Windows Server DNS became authoritative for:

```text
lab.test
```

The server began using its own local DNS service:

```text
::1
127.0.0.1
```

A DNS forwarder was configured on DC01:

```text
<LAB_GATEWAY>
```

The resulting DNS path is:

```text
Lab client
→ DC01 DNS
→ OPNsense
→ upstream DNS
```

The OPNsense forwarder resolved as:

```text
fw01.internal
```

## 22. DNS Verification

The following commands were used:

```powershell
Resolve-DnsName dc01.lab.test
Resolve-DnsName example.com
nslookup -type=SRV _ldap._tcp.dc._msdcs.lab.test
```

The results confirmed:

```text
dc01.lab.test → <DC_IP>
```

External DNS resolution also succeeded.

The LDAP SRV lookup returned:

```text
Service:  _ldap
Protocol: _tcp
Port:     389
Target:   dc01.lab.test
```

This confirmed that domain clients should be able to discover the domain controller.

## 23. Final Network Topology

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
dc01
<DC_IP>
dc01.lab.test
AD DS + DNS
```

## 24. Current Status

| Item | Status |
|---|---|
| Internal Proxmox bridge created | Complete |
| vmbr1 activated | Complete |
| OPNsense VM created | Complete |
| OPNsense installed | Complete |
| WAN configured | Complete |
| LAN configured | Complete |
| DHCP configured | Complete |
| NAT and internet access verified | Complete |
| DC01 moved to vmbr1 | Complete |
| DC01 static IP configured | Complete |
| AD DS installed | Complete |
| New forest created | Complete |
| Domain controller promotion completed | Complete |
| DNS Server installed | Complete |
| DNS forwarder configured | Complete |
| Internal DNS verified | Complete |
| External DNS verified | Complete |
| LDAP SRV record verified | Complete |

## 25. Problems Encountered

1. `fw01` initially failed to start because `vmbr1` had been configured but not yet applied.
2. The Proxmox bridge configuration had to be activated before the VM could use it.
3. OPNsense originally had only 2 GB RAM, which was insufficient for the installer.
4. The OPNsense interfaces were initially assigned in reverse.
5. The WAN private-network blocking option had to be disabled because the WAN sits on the private home network.
6. `dc01` initially used DHCP before receiving its final static address.
7. The PowerShell commands `Get-ADDomain` and `Get-ADForest` were first entered with underscores instead of hyphens.
8. The Windows keyboard layout changed to English after promotion and had to be switched back to German.

All issues were resolved before the session ended.

## 26. Lessons Learned

A Proxmox bridge can exist in the configuration without being active until the network changes are applied.

An internal bridge does not require a physical network adapter.

A virtual firewall requires clearly separated WAN and LAN interfaces.

Interface order must be verified before assigning WAN and LAN roles.

OPNsense blocks RFC1918 traffic on WAN by default, which is unsuitable when its WAN is connected to another private network.

A domain controller should use a static IP address.

Active Directory depends heavily on DNS.

Domain clients must use the domain controller as their DNS server rather than OPNsense directly.

The domain controller can forward external DNS requests to OPNsense.

DNS SRV records are required so clients can discover services such as LDAP and the domain controller.

A DNS delegation warning is expected when creating the first domain controller in a standalone test forest.

The `.test` namespace is suitable for isolated test environments and avoids using `.local`.

## 27. Next Steps

The next planned task is to create the first domain-joined Windows client.

```text
Target name: client01
Network:     vmbr1
Planned IP:  <CLIENT_IP>
DNS server:  <DC_IP>
Domain:      lab.test
```

The next session will include:

* creating or cloning the Windows client,
* attaching it to `vmbr1`,
* configuring its network settings,
* joining it to `lab.test`,
* creating organizational units,
* creating test users and groups,
* testing domain logins,
* and beginning Group Policy configuration.

The current OPNsense and Active Directory systems should remain unchanged until the first client is ready.
