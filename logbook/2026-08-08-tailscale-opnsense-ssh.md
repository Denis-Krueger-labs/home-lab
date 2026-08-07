# Remote SSH Access into the Isolated Home Lab through Proxmox, OPNsense and Tailscale

**Date:** 8 August 2026  
**Hypervisor:** Proxmox VE 9.2  
**Firewall:** OPNsense `fw01`  
**Remote Access:** Tailscale  
**Internal Lab Network:** `10.20.0.0/24`  
**Management Network:** `192.168.178.0/24`  
**Initial Target:** Ubuntu Server `copyfail01` at `10.20.0.191`  
**Goal:** Allow secure SSH access from the physical Windows workstation into selected systems inside the isolated OPNsense lab network without installing Tailscale directly on the research targets.

## 1. Starting Point

The home lab already used OPNsense as the gateway between the normal home network and the isolated virtual lab.

The relevant topology was:

```text
Physical Windows workstation
        |
        | Tailscale
        v
Proxmox VE
pve-home
192.168.178.53
        |
        | vmbr0
        v
OPNsense fw01
WAN: 192.168.178.58
LAN: 10.20.0.1
        |
        | vmbr1
        v
Isolated lab network
10.20.0.0/24
```

The OPNsense interfaces were:

```text
WAN       192.168.178.58/24
LAN       10.20.0.1/24
homelabWG 10.30.0.1/24
```

The Proxmox host was already reachable remotely through Tailscale:

```text
pve-home     100.111.191.59
denis-dell   100.120.76.52
```

The isolated lab itself was not yet routed through Tailscale.

The first SSH target was the new Ubuntu research VM:

```text
Hostname: copyfail01
Address:  10.20.0.191
User:     researcher
SSH:      TCP/22
```

The VM was intentionally kept free of Tailscale or other remote-management software so that it could remain a relatively clean research target.

## 2. Initial SSH Failure

SSH from the physical Windows machine initially failed:

```powershell
ssh researcher@10.20.0.191
```

Result:

```text
ssh: connect to host 10.20.0.191 port 22: Connection timed out
```

Before debugging the network, the SSH service itself was verified from the Ubuntu console:

```bash
ss -ltnp | grep ':22'
```

Result:

```text
LISTEN 0 128 0.0.0.0:22 0.0.0.0:* users:(("sshd",pid=906,fd=6))
LISTEN 0 128 [::]:22    [::]:*    users:(("sshd",pid=906,fd=7))
```

This confirmed that OpenSSH was listening correctly on all IPv4 and IPv6 interfaces.

The problem was therefore somewhere in the network path rather than inside the Ubuntu SSH configuration.

## 3. Verifying the Internal OPNsense-to-VM Path

The next step was to determine whether OPNsense itself could reach the Ubuntu VM.

An ICMP test from OPNsense to:

```text
10.20.0.191
```

succeeded.

TCP connectivity was then tested directly from the OPNsense shell:

```bash
nc -vz -w 3 10.20.0.191 22
```

Result:

```text
Connection to 10.20.0.191 22 port [tcp/ssh] succeeded!
```

This proved that the following part of the network was healthy:

```text
OPNsense LAN
10.20.0.1
    |
    v
copyfail01
10.20.0.191:22
```

At this point the following components were known to work:

```text
Ubuntu SSH service        Working
Ubuntu network interface Working
OPNsense LAN routing      Working
TCP/22 to copyfail01      Working
```

The failure had to exist between Proxmox and the OPNsense forwarding path.

## 4. Adding a Proxmox Route to the Lab Network

The Proxmox host initially had no route for the isolated network.

The routing table contained:

```text
default via 192.168.178.1 dev vmbr0
192.168.178.0/24 dev vmbr0
```

A lookup for the Ubuntu VM showed that Proxmox incorrectly attempted to send the traffic toward the home router:

```bash
ip route get 10.20.0.191
```

Result:

```text
10.20.0.191 via 192.168.178.1 dev vmbr0 src 192.168.178.53
```

A temporary route was added through the OPNsense WAN address:

```bash
ip route add 10.20.0.0/24 via 192.168.178.58 dev vmbr0
```

The routing decision then became:

```text
10.20.0.191 via 192.168.178.58 dev vmbr0 src 192.168.178.53
```

The route itself was therefore correct.

However, TCP connections still timed out:

```bash
nc -vz -w 3 10.20.0.191 22
```

Result:

```text
10.20.0.191: inverse host lookup failed: Unknown host
(UNKNOWN) [10.20.0.191] 22 (ssh) : Connection timed out
```

The inverse-host-lookup warning was unrelated to the failure. It only indicated that no reverse DNS record existed for the target address.

## 5. Verifying Layer 2 Connectivity

Because even a direct ping from Proxmox to the OPNsense WAN address did not receive replies, Layer 2 connectivity was checked explicitly.

The ARP table contained:

```bash
ip neigh show 192.168.178.58
```

Result:

```text
192.168.178.58 dev vmbr0 lladdr bc:24:11:e2:62:6c STALE
```

ARP requests were then sent directly:

```bash
arping -I vmbr0 -c 3 192.168.178.58
```

Result:

```text
ARPING 192.168.178.58 from 192.168.178.53 vmbr0

Unicast reply from 192.168.178.58 [BC:24:11:E2:62:6C]
Unicast reply from 192.168.178.58 [BC:24:11:E2:62:6C]
Unicast reply from 192.168.178.58 [BC:24:11:E2:62:6C]

Sent 3 probes
Received 3 response(s)
```

This proved that Proxmox and the OPNsense WAN interface could communicate correctly at Layer 2.

The failed ICMP test was therefore not evidence of a broken bridge or missing virtual connection.

## 6. Following the SSH SYN through Proxmox

Rather than continuing to change firewall settings blindly, the SSH connection was traced through each network layer.

A capture was started on the Proxmox management bridge:

```bash
tcpdump -ni vmbr0 'host 10.20.0.191 and tcp port 22'
```

The SSH test was triggered again:

```bash
nc -vz -w 3 10.20.0.191 22
```

The capture showed:

```text
192.168.178.53.59688 > 10.20.0.191.22: Flags [S]
192.168.178.53.59688 > 10.20.0.191.22: Flags [S]
192.168.178.53.59688 > 10.20.0.191.22: Flags [S]
```

The repeated SYN packets proved that:

```text
Proxmox routing decision  Working
Packet generation         Working
vmbr0 transmission        Working
```

No SYN-ACK returned.

## 7. Following the Packet into the OPNsense VM

The OPNsense VM configuration was inspected:

```bash
qm config 210 | grep '^net'
```

Result:

```text
net0: virtio=BC:24:11:E2:62:6C,bridge=vmbr0
net1: virtio=BC:24:11:9D:14:CF,bridge=vmbr1
```

The MAC address of `net0` matched the address discovered through ARP:

```text
BC:24:11:E2:62:6C
```

This confirmed that:

```text
net0 = OPNsense WAN
net1 = OPNsense LAN
```

Traffic was then captured directly on the Proxmox-side tap interface of the OPNsense WAN adapter:

```bash
tcpdump -eni tap210i0 'host 10.20.0.191 and tcp port 22'
```

The capture showed:

```text
00:4e:01:bc:7d:df > bc:24:11:e2:62:6c
192.168.178.53.48490 > 10.20.0.191.22: Flags [S]
```

This proved that the SSH SYN reached the virtual network adapter belonging to OPNsense.

The packet path was now confirmed as:

```text
Proxmox
   |
   v
vmbr0
   |
   v
tap210i0
   |
   v
OPNsense WAN adapter
```

## 8. Following the Packet inside OPNsense

A packet capture was then performed directly inside OPNsense:

```bash
tcpdump -ni vtnet0 'host 10.20.0.191 and tcp port 22'
```

The SYN appeared on `vtnet0`.

A second capture was started on the LAN interface:

```bash
tcpdump -ni vtnet1 'host 10.20.0.191 and tcp port 22'
```

No corresponding packet appeared.

This narrowed the problem to the OPNsense packet-filtering stage:

```text
PVE routing         Working
vmbr0               Working
tap210i0            Working
OPNsense vtnet0     Working
pf firewall         Suspect
OPNsense vtnet1     No packet
copyfail01          Never reached
```

## 9. Identifying the Exact OPNsense Firewall Rule

The packet-filter log was inspected directly:

```bash
tcpdump -n -e -ttt -i pflog0 'host 10.20.0.191 and tcp port 22'
```

The result identified the blocking firewall rule:

```text
rule 80/0(match): block in on vtnet0
192.168.178.53 > 10.20.0.191.22
```

The active pf ruleset was then inspected:

```bash
pfctl -vvsr | grep -A6 -B2 '@80 '
```

Rule `@80` contained:

```text
@80 block drop in log quick on vtnet0 inet from 192.168.0.0/16 to any
```

The source address of Proxmox was:

```text
192.168.178.53
```

which belongs to:

```text
192.168.0.0/16
```

The rule therefore matched the Proxmox traffic.

The most important part of the rule was:

```text
quick
```

In pf, a matching `quick` rule stops further rule evaluation.

This meant that the custom SSH allow rule was never reached.

The packet was dropped earlier by the automatically generated RFC1918 protection rule.

## 10. Root Cause

The root cause was the OPNsense WAN option:

```text
Block private networks
```

This option is useful when the WAN interface is connected directly to a public network.

In this lab, however, OPNsense WAN intentionally exists inside the private home network:

```text
OPNsense WAN: 192.168.178.58
Proxmox:      192.168.178.53
Home LAN:     192.168.178.0/24
```

Private RFC1918 traffic on the WAN interface is therefore expected.

With `Block private networks` enabled, OPNsense generated an early `quick` rule blocking the entire:

```text
192.168.0.0/16
```

range.

The setting was disabled on the OPNsense WAN interface.

The normal OPNsense firewall policy remained active.

## 11. Successful Proxmox-to-Lab SSH

After disabling the inappropriate RFC1918 WAN block, the TCP test succeeded:

```bash
nc -vz -w 3 10.20.0.191 22
```

Result:

```text
10.20.0.191: inverse host lookup failed: Unknown host
(UNKNOWN) [10.20.0.191] 22 (ssh) open
```

The reverse lookup warning is harmless.

The important result was:

```text
22 (ssh) open
```

SSH from Proxmox then succeeded:

```bash
ssh researcher@10.20.0.191
```

This confirmed the complete path:

```text
PVE
192.168.178.53
        |
        v
OPNsense WAN
192.168.178.58
        |
        v
OPNsense firewall
        |
        v
OPNsense LAN
10.20.0.1
        |
        v
copyfail01
10.20.0.191:22
```

## 12. Tailscale Subnet Routing

The next goal was to allow the physical Windows workstation to reach the lab network directly through the existing Tailscale connection to Proxmox.

The desired path was:

```text
Windows workstation
100.120.76.52
        |
        | Tailscale
        v
pve-home
100.111.191.59
192.168.178.53
        |
        v
OPNsense
        |
        v
10.20.0.0/24
```

Linux IP forwarding was initially disabled:

```bash
sysctl net.ipv4.ip_forward
```

Result:

```text
net.ipv4.ip_forward = 0
```

It was enabled for testing:

```bash
sysctl -w net.ipv4.ip_forward=1
```

The Proxmox Tailscale client then advertised the complete internal lab network:

```bash
tailscale set --advertise-routes=10.20.0.0/24
```

The route was subsequently approved in the Tailscale administration interface.

The advertised route covers the complete subnet:

```text
10.20.0.0/24
```

rather than only the current Ubuntu VM.

## 13. Successful Windows-to-Lab Connection

Connectivity was tested from the physical Windows workstation:

```powershell
Test-NetConnection 10.20.0.191 -Port 22
```

Result:

```text
ComputerName     : 10.20.0.191
RemoteAddress    : 10.20.0.191
RemotePort       : 22
InterfaceAlias   : Tailscale
SourceAddress    : 100.120.76.52
TcpTestSucceeded : True
```

This confirmed that Windows correctly selected Tailscale for the route.

SSH then succeeded:

```powershell
ssh researcher@10.20.0.191
```

The first connection added the Ubuntu host key to the Windows SSH known-hosts database.

The successful login showed:

```text
Welcome to Ubuntu 24.04.2 LTS
GNU/Linux 6.8.0-137-generic x86_64
```

The Ubuntu system reported the previous connection as originating from:

```text
192.168.178.53
```

This showed that the Tailscale subnet router was masquerading the connection through the Proxmox host.

The complete working path became:

```text
Physical Windows workstation
100.120.76.52
        |
        | Tailscale
        v
pve-home
100.111.191.59
192.168.178.53
        |
        | static route
        v
fw01 WAN
192.168.178.58
        |
        | OPNsense filtering
        v
fw01 LAN
10.20.0.1
        |
        v
copyfail01
10.20.0.191
```

## 14. Persistent Proxmox Routing

The temporary Proxmox route was made persistent in:

```text
/etc/network/interfaces
```

The final `vmbr0` configuration contains:

```text
auto vmbr0
iface vmbr0 inet static
        address 192.168.178.53/24
        gateway 192.168.178.1
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
        post-up ip route replace 10.20.0.0/24 via 192.168.178.58 dev vmbr0
        pre-down ip route del 10.20.0.0/24 via 192.168.178.58 dev vmbr0 || true
```

The route applies to the complete lab subnet:

```text
10.20.0.0/24
```

and forwards it through:

```text
192.168.178.58
```

which is the OPNsense WAN interface.

The Proxmox host itself remains without an address on `vmbr1`.

This is intentional.

The hypervisor is therefore not directly attached at Layer 3 to the isolated research network.

## 15. Persistent IP Forwarding

Tailscale subnet routing requires Linux forwarding.

A persistent sysctl configuration was created at:

```text
/etc/sysctl.d/99-tailscale-subnet-router.conf
```

with:

```text
net.ipv4.ip_forward=1
```

The live system had already been enabled with:

```bash
sysctl -w net.ipv4.ip_forward=1
```

The sysctl file ensures that forwarding is restored after reboot.

## 16. Firewall Access Model

Tailscale and Proxmox now know how to route the complete:

```text
10.20.0.0/24
```

network.

This does not automatically allow unrestricted access to every lab machine.

Routing and firewall authorization remain separate.

The current OPNsense rule allows:

```text
Source:
192.168.178.53

Destination:
10.20.0.191

Protocol:
TCP

Destination port:
22
```

Therefore:

```text
Windows -> Tailscale -> PVE -> copyfail01:22
```

is allowed.

A connection to another internal VM can be routed correctly but will still be denied by OPNsense unless a matching firewall rule exists.

For example:

```text
10.20.0.42
```

already belongs to the advertised and routed network.

However:

```powershell
ssh user@10.20.0.42
```

should remain blocked until that machine is explicitly approved by firewall policy.

## 17. Future SSH Access

Future Linux systems should not require additional Tailscale routes as long as they remain inside:

```text
10.20.0.0/24
```

The existing route already covers the entire subnet.

New systems only require deliberate OPNsense authorization.

For a small number of systems, individual rules can remain explicit:

```text
PVE -> copyfail01 -> TCP/22
PVE -> linux01    -> TCP/22
PVE -> linux02    -> TCP/22
```

If the number of managed systems increases, an OPNsense alias can be introduced.

Example:

```text
SSH_MANAGED_HOSTS

10.20.0.191    copyfail01
10.20.0.30     linux01
10.20.0.40     linux02
```

A single firewall rule could then permit:

```text
Source:
192.168.178.53

Destination:
SSH_MANAGED_HOSTS

Protocol:
TCP

Port:
22
```

This keeps management access explicit while avoiding an unrestricted rule such as:

```text
192.168.178.53 -> 10.20.0.0/24 -> any
```

The latter would unnecessarily allow every service on every internal system.

## 18. Security Considerations

Several design choices were intentionally preserved.

### 18.1 No Tailscale on Research Targets

Tailscale is installed on the Proxmox host rather than directly on `copyfail01`.

This keeps the Ubuntu research VM closer to its intended baseline and avoids introducing additional services, packages, interfaces, or network behavior into the system under study.

### 18.2 Proxmox Has No Address on vmbr1

The Proxmox host was not assigned an IP address inside:

```text
10.20.0.0/24
```

Instead, it reaches the subnet through OPNsense.

This ensures that OPNsense remains part of the management path rather than allowing the hypervisor to bypass the firewall.

### 18.3 Tailscale Does Not Replace OPNsense Policy

Tailscale provides the transport from the remote workstation to Proxmox.

OPNsense still determines which internal systems and services are reachable.

The layers therefore perform different jobs:

```text
Tailscale
Remote encrypted access

Proxmox
Subnet routing

OPNsense
Network segmentation and authorization

Target VM
Local service policy
```

### 18.4 WAN Private-Network Blocking

The OPNsense `Block private networks` WAN option remains disabled because the WAN interface intentionally exists inside an RFC1918 network.

This does not mean that the WAN interface is unrestricted.

Normal firewall filtering and explicit allow rules remain in effect.

## 19. Debugging Method

The most useful part of this troubleshooting session was following the same SYN packet through each network layer instead of repeatedly changing configuration options.

The investigation progressed through:

```text
1. Confirm SSH listener on target
2. Confirm OPNsense can reach target
3. Inspect Proxmox route
4. Add route through OPNsense
5. Verify ARP
6. Capture SYN on vmbr0
7. Capture SYN on tap210i0
8. Capture SYN on OPNsense vtnet0
9. Check for forwarding on vtnet1
10. Inspect pflog0
11. Identify pf rule @80
12. Correct WAN RFC1918 policy
13. Verify PVE SSH
14. Enable Linux forwarding
15. Advertise Tailscale subnet route
16. Approve Tailscale route
17. Verify Windows SSH
```

The key evidence chain was:

```text
SSH listening on copyfail01         Yes
OPNsense -> copyfail01:22           Yes
PVE route to 10.20.0.0/24           Yes
ARP to 192.168.178.58               Yes
SYN visible on vmbr0                Yes
SYN visible on tap210i0             Yes
SYN visible on OPNsense vtnet0      Yes
SYN visible on OPNsense vtnet1      No
pflog0 block                         Yes
Blocking rule                        @80
Reason                               RFC1918 WAN block
```

This located the failure precisely before configuration was changed.

## 20. Current Status

| Component | Status |
|---|---|
| Proxmox reachable through Tailscale | Working |
| OPNsense WAN | Working |
| OPNsense LAN | Working |
| Proxmox to OPNsense Layer 2 | Working |
| Proxmox route to `10.20.0.0/24` | Working |
| Persistent Proxmox route | Configured |
| Linux IPv4 forwarding | Enabled |
| Persistent IPv4 forwarding | Configured |
| Tailscale subnet advertisement | Working |
| Tailscale route approval | Working |
| Windows route through Tailscale | Working |
| OPNsense to `copyfail01` | Working |
| PVE to `copyfail01` SSH | Working |
| Windows to `copyfail01` SSH | Working |
| `copyfail01` Tailscale installation | Not required |
| OPNsense unrestricted lab access | Not enabled |
| Future VM SSH access | Requires firewall approval |

## 21. Current Network Structure

```text
                         Internet
                            |
                            v
                       Home Router
                      192.168.178.1
                            |
                 192.168.178.0/24
                            |
          +-----------------+------------------+
          |                                    |
          v                                    v
Physical Windows                        Proxmox VE
Tailscale client                        pve-home
100.120.76.52                           192.168.178.53
          |                                    |
          +---------- Tailscale ---------------+
                                               |
                                               |
                                   route 10.20.0.0/24
                                      via 192.168.178.58
                                               |
                                               v
                                         OPNsense fw01
                                   WAN: 192.168.178.58
                                   LAN: 10.20.0.1
                                               |
                                               |
                                         10.20.0.0/24
                                               |
                           +-------------------+-------------------+
                           |                   |                   |
                           v                   v                   v
                         dc01              client01          copyfail01
                     10.20.0.10          10.20.0.20        10.20.0.191
                                                               |
                                                               |
                                                            SSH/22
```

## 22. Lessons Learned

The largest lesson from this session was that a correct route does not imply that traffic will be forwarded successfully.

The Proxmox route was correct, but OPNsense intentionally discarded the packets because an automatically generated firewall rule matched before the custom allow rule.

Other useful lessons were:

* verify the target service before debugging the network,
* separate Layer 2, routing, firewall, and application problems,
* ARP is more useful than ICMP when checking same-subnet reachability,
* a failed ping does not automatically indicate broken Ethernet connectivity,
* use `tcpdump` at multiple points to follow the same packet,
* Proxmox tap interfaces provide useful visibility into VM traffic,
* `pflog0` can identify the exact pf rule responsible for a dropped packet,
* inspect the generated ruleset when a GUI rule appears correct but does not match,
* understand the effect of `quick` rules in pf,
* WAN assumptions change when the WAN interface itself lives on an RFC1918 network,
* routing an entire subnet does not mean every service must be permitted,
* keep Tailscale outside vulnerable research targets when possible,
* keep the firewall in the path rather than directly attaching the hypervisor to the isolated subnet,
* and use narrow service-specific firewall rules instead of broad management-network access.

## 23. Next Steps

The remote-access architecture is now functional enough to support future lab work.

### 23.1 Future Systems

New systems inside:

```text
10.20.0.0/24
```

do not require new Tailscale advertisements or Proxmox routes.

They only require explicit firewall authorization for the services that should be reachable remotely.

If the number of managed Linux systems grows, an OPNsense alias for SSH-managed hosts should be introduced.

### 23.2 Validation after Proxmox Reboot

The persistent route and sysctl configuration should be validated after the next planned Proxmox reboot.

The expected checks are:

```bash
ip route get 10.20.0.191
```

```bash
sysctl net.ipv4.ip_forward
```

```bash
tailscale status
```

The expected state is:

```text
10.20.0.0/24 routed through 192.168.178.58
net.ipv4.ip_forward = 1
pve-home connected to Tailscale
```

A final Windows test can then confirm persistence:

```powershell
Test-NetConnection 10.20.0.191 -Port 22
```

### 23.3 Copy Fail Research Lab

With remote SSH working, `copyfail01` can now be managed from the physical workstation without adding additional remote-access software to the target.

The next separate checkpoint will document the clean Ubuntu baseline for the Copy Fail research project.

That report should include:

* Ubuntu release information,
* exact kernel version,
* installed kernel packages,
* network configuration,
* user context,
* available package updates,
* clean snapshot state,
* and confirmation that no exploit or vulnerability reproduction has been performed yet.

## 24. Checkpoint Result

This session extended the home lab from a locally isolated environment into a remotely manageable but still firewall-controlled research network.

The physical workstation can now reach selected systems inside `10.20.0.0/24` through Tailscale, Proxmox performs subnet routing, and OPNsense remains responsible for deciding which internal hosts and services are actually accessible.

The troubleshooting process also identified and corrected an OPNsense WAN configuration mismatch caused by the lab's unusual but intentional private-WAN topology.

Remote management is now functional without installing Tailscale directly on the research VM, while future systems can be approved individually through OPNsense firewall policy.

The networking layer is therefore stable enough to continue with the Copy Fail Ubuntu baseline and vulnerability research.
