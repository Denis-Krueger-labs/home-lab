# Home Lab

> Building a tiny data center one component at a time, with room for both useful infrastructure and unnecessary technical nonsense.

This repository documents the setup and development of my personal home lab.

The lab is a place where I can build systems, break them, restore them, and test ideas without risking my main computer.

It is used for learning and experimenting with:

- Proxmox and virtualization
- Windows Server and Active Directory
- Linux and Windows administration
- Docker and self-hosted services
- network segmentation
- monitoring and logging
- backup and recovery
- CI/CD and automation
- defensive security
- authorized security testing

The home lab also acts as a smaller prototype for ideas that may later be used in the TTZ security test environment.

At the same time, not everything in the lab needs a serious purpose. It is also meant for dashboards, experimental systems, strange configurations, personal projects, and anything else that looks interesting enough to try.

Rather than showing only the finished result, this repository records the complete process, including hardware purchases, setup steps, configuration changes, mistakes, failures, fixes, and lessons learned.

## Current Status

**Current phase:** Proxmox foundation and reusable VM templates

The first node is operational.

Completed so far:

- hardware received and inspected
- defective RAM diagnosed and replaced
- full 32 GB RAM configuration verified
- Proxmox VE 9.2 installed
- management network configured
- Proxmox repositories corrected
- system fully updated
- external backup storage configured
- weekly automatic backup job created
- Debian 13 server template created

The next planned task is to create a reusable Windows Server template before deploying Active Directory.

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

## Current Proxmox Storage

| Storage | Purpose |
|---|---|
| `local` | ISO images, templates, imports, and local files |
| `local-lvm` | Virtual machine and container disks |
| `backup-ssd` | External VM and container backups |

## Backup Configuration

The external backup drive is mounted at:

```text
/mnt/pve/backup-ssd
```

The current automatic backup job uses:

```text
Schedule:    Sunday at 01:00
Selection:   All virtual machines and containers
Mode:        Snapshot
Compression: ZSTD
Retention:   Keep the last 3 backups
```

A full backup and restore test is still required.

## Current Templates

### Debian 13 Server Template

```text
VM ID: 100
Proxmox name: debian-gold
Guest hostname: tmpl-debian
```

The template includes:

- Debian 13
- UEFI with OVMF
- q35 machine type
- VirtIO SCSI
- VirtIO network interface
- QEMU guest agent
- Cloud-Init
- SSH
- sudo
- common command-line tools
- no desktop environment

The template is not used directly. New Debian servers are created as full clones.

### Planned Windows Server Template

The next reusable template will be based on Windows Server.

It will later be used to deploy:

- the first domain controller
- additional Windows Server roles
- temporary Windows Server test systems

The template will be prepared before Active Directory is installed so that the clean operating system base can be reused.

## Planned Environment

The first node is intended to host infrastructure and target systems such as:

- Windows Server with Active Directory Domain Services
- domain-joined Windows clients
- Debian infrastructure servers
- Docker workloads
- monitoring and logging systems
- CI/CD runners
- temporary project systems
- intentionally vulnerable targets
- honeypot services
- dashboards and personal experiments

Not every system will run at the same time.

The Dell represents the infrastructure, services, clients, targets, monitoring, and recovery environment.

Kali Linux remains external and will normally run on my laptop or another separate testing system.

## Planned Naming Structure

| Role | Example |
|---|---|
| Proxmox host | `pve` |
| Debian template | `debian-gold` |
| Windows Server template | `windows-server-gold` |
| Domain controller | `dc01` |
| Windows client | `client01` |
| Docker host | `docker01` |
| Monitoring server | `monitor01` |
| Firewall | `fw01` |
| Temporary lab system | `lab-example` |

The naming scheme may change as the environment grows.

## Documentation

- [Roadmap](docs/roadmap.md)
- [Hardware inventory](docs/hardware-inventory.md)
- [Logbook](logbook/)

Additional documentation will be added for:

- architecture
- network planning
- naming conventions
- backup and recovery
- virtual machine templates
- important technical decisions

## Repository Structure

```text
home-lab/
├── README.md
├── docs/
│   ├── hardware-inventory.md
│   └── roadmap.md
└── logbook/
    ├── 2026-07-13-project-start.md
    ├── 2026-07-15-first-issue.md
    ├── 2026-07-23-initial-proxmox.md
    └── 2026-07-24-proxmox-foundation-and-debian-template.md
```

Configuration files and scripts may be added later.

Passwords, tokens, private keys, and unfiltered configuration exports will not be committed.

## Disclaimer

This environment is intended exclusively for authorized education, experimentation, and security research.

Vulnerable services, malware samples, and offensive-security tools will only be used in isolated systems owned and controlled by the author.
