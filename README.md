# Home Lab

> Building a tiny data center one component at a time, with room for useful infrastructure, security experiments, and unnecessary technical nonsense.

This repository documents the design and development of my personal home lab.

The lab gives me a controlled environment where I can build systems, break them, observe what happened, restore them, and try again without risking my main computer or home network. It also serves as a smaller prototype for infrastructure and security concepts that may later be used in the TTZ security test environment.

Rather than presenting only a polished final result, this repository records the complete process, including hardware problems, setup decisions, configuration changes, failed attempts, fixes, checkpoints, and lessons learned.

## Current Status

**Last updated:** 4 August 2026  
**Current phase:** Core Windows infrastructure operational, network isolation established, remote access and recovery testing still in progress

The first node now runs a functional small enterprise-style lab behind a virtual OPNsense firewall.

Completed milestones include:

- Dell OptiPlex node tested, repaired, and placed into operation
- Proxmox VE 9.2 installed and updated
- external backup storage and weekly backup job configured
- reusable Debian 13 and Windows Server 2025 templates created
- isolated virtual lab network created with OPNsense
- Active Directory forest and DNS deployed for `lab.test`
- Windows 11 Enterprise client joined to the domain
- organizational units, users, security groups, and initial GPOs created
- manual infrastructure checkpoints created before major network changes
- WireGuard road-warrior configuration prepared in OPNsense
- Tailscale remote access to the Proxmox host tested successfully
- NixOS and Hyprland desktop prototype developed as the experimental **Mori OS** workstation

The original “first node and templates” stage is complete. The current priorities are backup restoration testing, remote-access hardening, continued Active Directory development, centralized monitoring, and documentation.

## Architecture at a Glance

```text
Remote laptop
    |
    | Tailscale, currently working
    | WireGuard, prepared but not externally validated
    v
Home network: 192.168.178.0/24
    |
    +-- pve              192.168.178.53
    |     Proxmox VE 9.2
    |
    +-- fw01 WAN         192.168.178.58
          OPNsense
              |
              | vmbr1
              v
        Isolated lab network: 10.20.0.0/24
              |
              +-- fw01 LAN     10.20.0.1
              +-- dc01         10.20.0.10
              |     AD DS, DNS, lab.test
              +-- client01     10.20.0.20
                    Windows 11 Enterprise
```

The Proxmox management interface is not exposed directly to the public internet.

## First Node

| Component | Specification |
|---|---|
| Model | Dell OptiPlex 5070 Micro |
| Processor | Intel Core i5-9500T |
| CPU | 6 cores / 6 threads |
| Memory | 32 GB RAM |
| Internal storage | 1 TB SSD |
| External backup storage | 1 TB USB drive |
| Network | 1× Gigabit Ethernet |
| Hypervisor | Proxmox VE 9.2 |
| Hostname | `pve` |
| Management address | `192.168.178.53` |
| Status | Operational |

The system originally arrived with a defective memory module. The fault was isolated through hardware testing, the system was returned, and the repaired machine was verified with the full 32 GB configuration before Proxmox was installed.

## Current Virtual Environment

| VM ID | Name | Role | Status |
|---:|---|---|---|
| 100 | `debian-gold` | Debian 13 server template | Ready |
| 110 | `windows-server-gold` | Windows Server 2025 template | Ready |
| 111 | `nix01` | NixOS and Mori OS desktop prototype | Active development |
| 200 | `dc01` | Active Directory domain controller and DNS | Operational |
| 210 | `fw01` | OPNsense firewall and lab router | Operational |
| 220 | `client01` | Windows 11 Enterprise domain client | Operational |

Not every system is expected to run continuously. Resource allocation is adjusted according to the current experiment.

## Active Directory Environment

| Item | Value |
|---|---|
| DNS domain | `lab.test` |
| NetBIOS domain | `LAB` |
| Domain controller | `DC01` |
| Domain controller address | `10.20.0.10` |
| First workstation | `CLIENT01` |
| Workstation address | `10.20.0.20` |
| Internal DNS | `DC01` |
| External DNS forwarding | OPNsense |

Current organizational structure:

```text
lab.test
├── Domain Controllers
│   └── DC01
├── Workstations
│   └── CLIENT01
├── Servers
├── Lab Users
│   └── Nyx Valborne
├── Groups
│   └── GG-Lab-Users
└── Service Accounts
```

Initial Group Policy work includes separate workstation and user baselines. Domain login, secure-channel health, group membership, computer policy processing, and user policy processing have all been verified.

## Network Segmentation

Two Proxmox bridges currently separate management and lab traffic:

| Bridge | Purpose |
|---|---|
| `vmbr0` | Home network, Proxmox management, and OPNsense WAN |
| `vmbr1` | Isolated virtual lab network behind OPNsense |

Current networks:

| Network | Purpose |
|---|---|
| `192.168.178.0/24` | Home and management network |
| `10.20.0.0/24` | Isolated infrastructure and domain network |
| `10.30.0.0/24` | Prepared WireGuard VPN network |

OPNsense provides routing, NAT, DHCP where required, DNS forwarding, and the firewall boundary between the home network and the internal lab.

## Remote Access

A WireGuard road-warrior configuration has been prepared in OPNsense:

```text
Instance:       HomeLab-WG
Interface:      wg0
Tunnel address: 10.30.0.1/24
Laptop address: 10.30.0.2/32
Listen port:    UDP 51820
```

The keys, peer configuration, interface assignment, and firewall rules are present. External handshake and routing tests are still pending.

Tailscale is currently used as the practical remote-management path. Connectivity between the Windows laptop and the Proxmox host `pve-home` has been verified without exposing the Proxmox web interface directly to the internet.

## Backup Configuration

The external backup drive is mounted at:

```text
/mnt/pve/backup-ssd
```

The automatic backup job uses:

```text
Schedule:    Sunday at 01:00
Selection:   All virtual machines and containers
Mode:        Snapshot
Compression: ZSTD
Retention:   Keep the last 3 backups
```

Manual backups and checkpoints have also been created for important milestones, including:

- the generalized Windows Server template
- the OPNsense baseline
- the verified Active Directory configuration
- the domain-joined Windows client

A complete restore test and retention verification are still required before the backup process can be considered fully validated.

## Reusable Templates

### Debian 13 Server Template

```text
VM ID:          100
Proxmox name:   debian-gold
Guest hostname: tmpl-debian
```

The template includes UEFI, q35, VirtIO devices, QEMU Guest Agent, Cloud-Init, SSH, sudo, and common command-line tools. It has no desktop environment and is intended for full clones such as Docker hosts, monitoring servers, and temporary Linux infrastructure.

### Windows Server 2025 Template

```text
VM ID:        110
Proxmox name: windows-server-gold
Guest name:   WIN-SRV-TMPL
```

The template includes Windows Server 2025 Standard Evaluation with Desktop Experience, VirtIO drivers, QEMU Guest Agent, OpenSSH, current updates, TPM 2.0, UEFI, and Secure Boot support. It was generalized with Sysprep, backed up, and converted into a reusable Proxmox template before any server roles were installed.

## Mori OS Experiment

VM 111, `nix01`, is used to develop a custom NixOS and Hyprland desktop called **Mori OS**.

The current prototype includes:

- declarative NixOS configuration
- Hyprland with UWSM
- custom Waybar controls
- Quickshell panels integrated into a subway-themed desktop
- live CPU and memory information
- live Spotify metadata, artwork, and media controls through MPRIS
- a custom Mori settings launcher
- dark GTK configuration tools
- a multi-window minimized-application drawer
- Firefox, Obsidian, Visual Studio Code, Spotify, Discord, and common desktop tools

The VM is a safe development target for a future native installation on a Dell XPS 16. Hardware-specific configuration, a login screen, notification support, and several remaining live widgets are still unfinished.

Mori OS is an experimental personal project inside the lab, not a replacement for the core infrastructure environment.

## What the Lab Is For

The environment is being built for learning and experimentation with:

- Proxmox and virtualization
- Windows Server and Active Directory
- Linux and Windows administration
- network segmentation and firewalls
- VPN and remote-access design
- Docker and self-hosted services
- monitoring and centralized logging
- backup and recovery
- CI/CD and infrastructure automation
- defensive security engineering
- controlled and authorized security testing
- NixOS, Wayland, and desktop systems
- dashboards, strange configurations, and personal experiments

The Dell hosts infrastructure, services, clients, targets, monitoring, and recovery systems. Offensive testing systems normally remain external or are placed into explicitly isolated temporary networks.

## Current Priorities

1. Test restoration of a complete VM backup.
2. Confirm automatic backup execution and retention.
3. Finish and validate secure remote access.
4. Continue Active Directory development with additional roles, policies, and test identities.
5. Create the first Debian infrastructure clone and deploy containerized services.
6. Add centralized monitoring and logging.
7. Document the architecture, addressing plan, recovery process, and important decisions.
8. Continue Mori OS only when a break from enterprise infrastructure is medically necessary.

The detailed and longer-term task list is maintained in the [roadmap](docs/roadmap.md).

## Planned Expansion

Later phases may include:

- a reusable Windows 11 template
- Docker and reverse-proxy infrastructure
- Grafana, Prometheus, Loki, or Wazuh
- controlled attack, detection, and recovery exercises
- CI/CD runners and Ansible automation
- a small Kubernetes environment
- managed switching and VLANs
- a second compute node
- a compact rack and UPS
- a dedicated status display
- integration with a larger TTZ security test environment

## Documentation

- [Roadmap](docs/roadmap.md)
- [Hardware inventory](docs/hardware-inventory.md)
- [Logbook](logbook/)

The logbook contains dated reports for the hardware failure, Proxmox foundation, templates, OPNsense, Active Directory, Windows client, WireGuard preparation, NixOS, Hyprland, Mori Settings, and live desktop widgets. Sanitized NixOS configuration snapshots are stored under `nixos/`.

## Repository Structure

```text
home-lab/
├── README.md
├── docs/
│   ├── hardware-inventory.md
│   └── roadmap.md
├── nixos/
│   └── nix01/
│       ├── base_config/
│       ├── Config_26.07.30/
│       └── config_daily/
└── logbook/
    ├── 2026-07-13-project-start.md
    ├── 2026-07-15-first-issue.md
    ├── 2026-07-23-initial-proxmox.md
    ├── 2026-07-24-proxmox-foundation-and-debian-template.md
    ├── 2026-07-26-windows-server-template.md
    ├── 2026-07-27-opnsense-active-directory-setup-report.md
    ├── 2026-07-28-windows-11-enterprise-client-domain-join.md
    ├── 2026-07-28-active-directory-structure-users-groups-and-gpo.md
    ├── 2026-07-29-wireguard-remote-access-preparation.md
    ├── 2026-07-30-first-nixos-installation.md
    ├── 2026-07-30-first-hyprland-desktop.md
    ├── 2026-07-31-nixos-hyprland-mori-desktop.md
    ├── 2026-07-31-mori-os-daily-driver-milestone.md
    ├── 2026-08-01-mori-settings-control-node.md
    └── 2026-08-02-mori-os-live-widgets-and-window-drawer.md
```

Sanitized configuration snapshots are included for `nix01`, and additional reusable configuration files and scripts may be added as the lab develops. Passwords, tokens, private keys, recovery secrets, and unfiltered configuration exports must never be committed.

## Disclaimer

This environment is intended exclusively for authorized education, experimentation, system administration, and security research.

Vulnerable services, malware samples, and offensive-security tools will only be used in isolated systems owned and controlled by the author. The lab must not be used to access, test, or interfere with systems without explicit authorization.
