# WireGuard Remote Access Preparation

**Date:** 29 July 2026  
**System:** Dell OptiPlex 5070 Micro  
**Platform:** Proxmox VE 9.2  
**Firewall:** VM 210, `fw01`  
**VPN technology:** WireGuard  
**Goal:** Prepare secure road-warrior VPN access to the isolated home-lab network without exposing Proxmox or internal services directly to the internet.

## 1. Starting Point

The following infrastructure was already operational:

```text
Proxmox node: pve
Proxmox management IP: <PVE_MANAGEMENT_IP>
OPNsense firewall: fw01
OPNsense WAN: <OPNSENSE_WAN_IP>
OPNsense LAN: <LAB_GATEWAY>
Lab network: <LAB_SUBNET>
Domain controller: <DC_IP>
Windows client: <CLIENT_IP>
```

The intended remote-access path was:

```text
Remote laptop or Kali VM
→ WireGuard
→ public home connection
→ FRITZ!Box
→ OPNsense
→ internal lab network
```

## 2. VPN Technology Selection

WireGuard was selected because it is simple, lightweight, key-based, well supported on Windows and Linux, and suitable for a personal road-warrior VPN.

OpenVPN may be tested later for certificate, user-account, and MFA practice.

IPsec may be tested later for site-to-site and enterprise VPN practice.

## 3. WireGuard Addressing Plan

A separate VPN subnet was selected:

```text
<WG_SUBNET>
```

The initial addressing plan was:

```text
OPNsense WireGuard instance: <WG_GATEWAY_IP>
Laptop WireGuard client:     <WG_CLIENT_IP>
```

This does not overlap with:

```text
Lab network:  <LAB_SUBNET>
Home network: <MANAGEMENT_SUBNET>
```

## 4. WireGuard Instance Creation

A new instance was created in OPNsense:

```text
Name:           HomeLab-WG
Device:         wg0
Listen port:    51820
Tunnel address: <WG_GATEWAY_IP>/24
MTU:            1420
Enabled:        yes
```

OPNsense generated its own private and public key pair.

The private key remained only on OPNsense.

## 5. MTU Configuration

The WireGuard MTU was set to:

```text
1420
```

This leaves room for the additional WireGuard, UDP, and IP headers and reduces the risk of fragmentation on networks using a normal Ethernet MTU of 1500 bytes.

## 6. Laptop Key Pair

The official WireGuard client was installed on the laptop.

A tunnel named:

```text
HomeLab
```

was created.

The client generated its own private and public key pair.

The laptop private key remained only on the laptop.

The laptop public key was added to OPNsense.

## 7. WireGuard Peer Creation

A peer was created in OPNsense:

```text
Enabled:          yes
Name:             Laptop
Public key:       laptop public key
Pre-shared key:   none
Allowed IPs:      <WG_CLIENT_IP>/32
Endpoint address: empty
Endpoint port:    empty
Instance:         HomeLab-WG
```

The endpoint fields remained empty because the laptop is a roaming client and may connect from different networks.

## 8. Public Key Transfer

The Proxmox console did not provide a usable clipboard.

Direct access to the OPNsense GUI through its WAN address also did not work.

Python was not installed on the laptop, so a temporary Python web server could not be used.

The two public keys were eventually transferred through a private online note that was accessible from both the laptop and `CLIENT01`.

Only public keys were transferred.

No private key was moved between systems.

## 9. WireGuard Activation

WireGuard was enabled in OPNsense.

The active instance appeared as:

```text
HomeLab-WG
wg0
<WG_GATEWAY_IP>/24
UDP 51820
```

The Laptop peer was associated with the instance.

## 10. Interface Assignment

The WireGuard device was assigned as a new OPNsense interface:

```text
Description: HomeLabWG
Device:      wg0
Lock:        enabled
```

The interface was configured with:

```text
Enable interface:          enabled
Prevent interface removal: enabled
IPv4 configuration type:   None
IPv6 configuration type:   None
Block private networks:     disabled
Block bogon networks:       disabled
```

The address `<WG_GATEWAY_IP>/24` was not entered again because it is already owned by the WireGuard instance.

## 11. WAN Firewall Rule

A WAN rule was created:

```text
Action:           Pass
Interface:        WAN
Direction:        in
TCP/IP version:   IPv4
Protocol:         UDP
Source:           any
Destination:      WAN address
Destination port: 51820
Description:      Allow WireGuard VPN
```

This exposes only the WireGuard UDP listener.

It does not expose Proxmox, RDP, SSH, the OPNsense GUI, or internal VMs directly.

## 12. WireGuard Interface Rule

A rule was created on `HomeLabWG`:

```text
Action:           Pass
Interface:        HomeLabWG
Direction:        in
TCP/IP version:   IPv4
Protocol:         any
Source:           WireGuard client traffic
Destination:      <LAB_SUBNET>
Destination port: any
Description:      Allow WireGuard clients to lab network
```

This initially permits VPN clients to access only the isolated lab subnet.

## 13. Laptop Tunnel Configuration

The laptop configuration was prepared as:

```ini
[Interface]
PrivateKey = <LAPTOP_PRIVATE_KEY>
Address = <WG_CLIENT_IP>/32
DNS = <DC_IP>

[Peer]
PublicKey = <OPNSENSE_PUBLIC_KEY>
AllowedIPs = <LAB_SUBNET>, <WG_SUBNET>
Endpoint = <PUBLIC_IP_OR_DDNS_NAME>:51820
PersistentKeepalive = 25
```

The endpoint remains incomplete until a public IP address or DDNS hostname is available.

## 14. DNS Dependency During Configuration

`CLIENT01` temporarily appeared to have no internet access.

Its DNS server is:

```text
<DC_IP>
```

which is `DC01`.

The issue occurred because `DC01` was powered off.

The dependency was:

```text
DC01 offline
→ no Active Directory DNS
→ CLIENT01 cannot resolve internet names
```

After starting `DC01`, DNS and browser access worked again.

## 15. FRITZ!Box Port Forward Requirement

Remote connections cannot yet reach OPNsense because the FRITZ!Box still needs this forwarding rule:

```text
Protocol:        UDP
External port:   51820
Internal device: OPNsense
Internal IP:     <OPNSENSE_WAN_IP>
Internal port:   51820
```

The intended path is:

```text
Remote laptop
→ public IP or DDNS hostname
→ FRITZ!Box UDP 51820
→ OPNsense <OPNSENSE_WAN_IP>:51820
→ WireGuard
→ <LAB_SUBNET>
```

This step must be completed when access to the home FRITZ!Box is available.

## 16. Public Endpoint Requirement

The laptop configuration still requires one of:

```text
Public IPv4 address
MyFRITZ! hostname
Dynamic DNS hostname
Suitable IPv6 endpoint
```

The endpoint must not use:

```text
<OPNSENSE_WAN_IP>
```

for remote access because that is only OPNsense's private WAN address inside the home network.

## 17. Proxmox Remote Access

The current VPN rule allows access only to:

```text
<LAB_SUBNET>
```

Proxmox management is located at:

```text
<PVE_MANAGEMENT_IP>
```

Remote Proxmox access has not yet been enabled.

It will require a separate explicit routing and firewall rule.

The Proxmox web interface must never be forwarded directly through the FRITZ!Box.

## 18. Current Status

| Item | Status |
|---|---|
| WireGuard subnet selected | Complete |
| OPNsense WireGuard instance created | Complete |
| OPNsense keys generated | Complete |
| Laptop WireGuard tunnel created | Complete |
| Laptop key pair generated | Complete |
| Laptop peer created in OPNsense | Complete |
| Public keys exchanged | Complete |
| WireGuard enabled | Complete |
| wg0 assigned as HomeLabWG | Complete |
| WAN UDP 51820 rule created | Complete |
| VPN-to-lab firewall rule created | Complete |
| Laptop configuration prepared | Complete |
| FRITZ!Box port forwarding | Pending |
| Public IP or DDNS endpoint | Pending |
| External handshake test | Pending |
| Remote lab connectivity test | Pending |
| Remote Proxmox access rule | Pending |

## 19. Problems Encountered

1. The OPNsense console was initially mistaken for the web interface.
2. The WireGuard menu layout differed from the expected layout.
3. The WireGuard enable checkbox was easy to overlook.
4. Interface Assignments was difficult to locate.
5. The Proxmox console did not provide a usable clipboard.
6. Direct OPNsense GUI access through its WAN address did not work.
7. Python and the Windows Python launcher were not installed.
8. Public-key transfer required an alternative method.
9. `CLIENT01` lost DNS resolution while `DC01` was powered off.
10. Remote testing could not be completed without the FRITZ!Box port forward.

## 20. Lessons Learned

WireGuard uses a separate key pair on each endpoint.

Private keys never leave the device that generated them.

Each side receives only the other side's public key.

The VPN subnet must not overlap existing networks.

The WAN rule allows WireGuard packets to reach OPNsense.

The `HomeLabWG` rule determines which internal networks VPN clients may access.

Opening UDP 51820 does not expose the internal services directly.

A router port forward is required because OPNsense is behind the FRITZ!Box.

The client endpoint must use a public address or DDNS hostname.

Active Directory clients depend on the domain controller for DNS when they use the DC as their DNS server.

## 21. Next Steps

When access to the FRITZ!Box is available:

1. Confirm or reserve OPNsense's WAN address:

```text
<OPNSENSE_WAN_IP>
```

2. Create the UDP forwarding rule:

```text
51820 → <OPNSENSE_WAN_IP>:51820
```

3. Identify the public IP or configure MyFRITZ!/DDNS.

4. Complete the laptop endpoint:

```ini
Endpoint = <PUBLIC_IP_OR_DDNS_NAME>:51820
```

5. Test from an external network such as a phone hotspot.

6. Verify the WireGuard handshake.

7. Test access to:

```text
<WG_GATEWAY_IP>
<LAB_GATEWAY>
<DC_IP>
<CLIENT_IP>
```

8. Confirm DNS through `<DC_IP>`.

9. Add a separate restricted rule for Proxmox if required.

10. Test remote access from the Kali VM.

The current setup is prepared but not yet externally verified.
