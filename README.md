# Home Lab

> Building a tiny enterprise network in a Dell that absolutely did not consent to this much responsibility.


This repository documents the design, construction, breakage, recovery and continued evolution of my personal home lab.

What started as a small virtualization node has gradually turned into a compact enterprise-style environment for identity services, Windows and Linux administration, network segmentation, defensive security research, controlled attack-and-defence exercises and reproducible security testing.

The goal is not just to show a polished end state. The repository also records decisions, failed attempts, rebuilds and the lessons learned while the lab grows.

> **OPSEC note:** This is a public project. Internal addressing, hostnames, domain names, management paths, credentials, firewall rules and other operational details are intentionally omitted or generalized.

## Current state

The lab is actively running and currently includes:

- Proxmox VE as the virtualization platform
- an isolated lab network behind a virtual firewall
- an Active Directory environment
- Windows Server and Windows workstation systems
- reusable Windows and Linux VM templates
- dedicated infrastructure and file services
- Group Policy and internal DNS
- a separated privileged-administration workflow currently being expanded
- authenticated remote management without exposing the hypervisor directly to the public internet
- external backup and recovery workflows
- a NixOS-based Mori OS environment
- MORI and Copy Fail security research inside controlled lab systems

The current focus is moving privileged administration away from normal workstation use and into a dedicated management path before expanding the attack-and-defence side of the lab.

## Architecture

```text
Home network
     |
     +-- Virtualization host
            |
            +-- Virtual firewall / routing
                    |
                    +-- Isolated lab network
                           |
                           +-- Identity services
                           +-- Windows workstations
                           +-- File / infrastructure services
                           +-- Privileged admin workstation
                           +-- NixOS / Mori OS environment
                           +-- Temporary research targets
```

The internal systems are placed behind a dedicated firewall instead of being treated as ordinary devices on the home network. This provides a controlled environment for infrastructure testing and later security exercises while keeping the public documentation intentionally high level.

## Core capabilities

### Virtualization and reproducibility

The lab uses reusable VM templates and documented build procedures so environments can be rebuilt instead of becoming irreplaceable snowflakes.

Current reusable bases include Windows Server and Debian systems, with additional purpose-built machines created from those foundations as needed.

### Active Directory lab

The Windows environment currently provides:

- Active Directory Domain Services
- internal DNS
- domain-joined clients and servers
- Group Policy
- dedicated file services
- a separate administrative workstation workflow

The administrative design is being expanded so privileged work is separated from normal user activity before the lab moves further into Active Directory attack-and-defence exercises.

Specific internal names, addresses and remote-management configuration are intentionally not published here.

## Mori OS, MORI and Copy Fail

And then there is the tiny guy carrying an unreasonable amount of responsibility.

**Mori OS** is my NixOS-based workstation environment and one of the more experimental parts of the lab. It gives me a reproducible Linux environment for system configuration work, interface experiments and security tooling.

The lab also supports development and testing around **Copy Fail** and **MORI**, including:

- controlled reproduction of Copy Fail / CVE-2026-31431
- detection experiments
- eBPF and userspace monitoring
- mitigation testing
- regression and validation runs
- repeatable testing inside disposable or recoverable systems

MORI grew out of the Copy Fail research and now forms part of the defensive-security side of the lab, where detection and mitigation ideas can be tested without relying on production infrastructure.

So yes, one little NixOS system is currently carrying an operating-system project, kernel-security research and an eBPF security gremlin. It is doing its best.

## Networking and isolation

The lab separates normal home infrastructure from security-testing systems through a dedicated virtual firewall and isolated network design.

That architecture provides a base for work involving:

- firewall policy testing
- network segmentation
- Active Directory attack paths
- intentionally vulnerable systems
- malware-analysis environments
- monitoring and detection

The public repository documents the design decisions and lessons learned without publishing the exact internal addressing scheme, routing configuration or firewall policy.

## Remote management

Remote administration is available through an authenticated private-access layer rather than exposing management interfaces directly to the public internet.

The exact access path, device identities and management configuration are deliberately kept out of the public README.

## Backup and recovery

The lab has external backup and recovery workflows for important virtual machines and configuration state.

Backups, snapshots and rebuildable templates are used before larger infrastructure changes or destructive testing. Recovery matters as much as deployment: if I am going to deliberately break systems, I would also like the ability to un-break them afterwards.

Detailed retention settings, storage layout and recovery paths are intentionally not published here.

## What works today

- [x] virtualization host
- [x] tested hardware baseline
- [x] external backup workflow
- [x] recurring VM backups
- [x] reusable Windows Server template
- [x] reusable Debian template
- [x] virtual firewall and isolated lab networking
- [x] Active Directory Domain Services
- [x] internal DNS
- [x] domain-joined Windows systems
- [x] Group Policy
- [x] dedicated file services
- [x] private remote management
- [x] NixOS / Mori OS environment
- [x] Copy Fail and MORI security experiments
- [ ] completed privileged-administration workflow
- [ ] full restore validation and recovery documentation

## Currently building

The immediate focus is the dedicated privileged-management path.

That includes:

- separating privileged and everyday identities
- administering directory services from a dedicated workstation
- remote infrastructure administration through controlled management channels
- validating administrative tooling and logging
- preparing the environment for later attack-and-defence exercises

Once that foundation is complete, the lab can lean harder into controlled security exercises rather than only building the infrastructure those exercises require.

## Where this is going

The roadmap is intentionally flexible, but the larger direction includes:

- Active Directory attack-and-defence exercises
- centralized logging and monitoring
- malware-analysis infrastructure
- intentionally vulnerable targets
- detection engineering exercises
- Docker and self-hosted services
- Kubernetes
- CI/CD
- infrastructure automation
- additional network segmentation
- honeypots
- additional physical nodes when the current Dell finally files for workers' compensation

Not all of these systems need to run at the same time. The lab is meant to be rebuilt, rearranged and adapted depending on what I am learning or testing.

## Hardware

The lab is deliberately being built from small-form-factor hardware rather than a full rack of enterprise systems.

The current setup includes:

- a compact x86 virtualization host
- upgraded memory and local SSD storage
- external backup storage
- a small managed physical network footprint

Part of the fun is seeing how much useful infrastructure can fit inside one tiny Dell before adding more machines.

Exact device inventory and configuration details may be documented privately where publishing them would add operational detail without adding much educational value.

## Documentation

This repository is meant to document the process rather than only the finished result.

- [Logbook](logbook/) records individual build sessions, failures and fixes.
- [Hardware inventory](docs/hardware-inventory.md) tracks the physical lab equipment where appropriate for public documentation.
- [Roadmap](docs/roadmap.md) tracks planned infrastructure and future experiments.

That means mistakes stay in the history too. A broken configuration that gets diagnosed and repaired is often more useful to document than a configuration that worked on the first try.

## Security and ethics

This environment is intended exclusively for authorized education, experimentation and security research.

Vulnerable services, offensive-security tooling, malware samples and exploit research are only used in systems that I own or am explicitly authorized to test. Potentially dangerous experiments are designed to stay inside controlled and isolated environments.

The point of the lab is to learn how systems fail, how those failures can be detected, and how the systems can be made harder to break the next time.
