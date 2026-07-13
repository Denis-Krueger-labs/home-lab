# Logbook 001: Project Start

**Date:** 13 July 2026  
**Status:** First hardware purchased

## What happened

Today I purchased the first physical component for my home lab: a refurbished Dell OptiPlex 5070 Micro.

The system has not arrived yet. This entry documents the purchase decision, the current plan and the expectations for the first node.

## What I bought

| Component | Specification |
|---|---|
| Model | Dell OptiPlex 5070 Micro |
| Processor | Intel Core i5-9500T |
| CPU configuration | 6 cores / 6 threads |
| Memory | 32 GB RAM |
| Storage | 1 TB SSD |
| Network interface | 1× Gigabit Ethernet |
| Included operating system | Windows 11 |
| Condition | Refurbished |
| Purchase price | €385.00 |
| Shipping | €5.99 |
| Total | €390.99 |

## Why I chose this system

I wanted a platform that could support several virtual machines without requiring a large, loud or power-hungry server.

The OptiPlex 5070 Micro offers a useful balance of:

- physical size
- low power consumption
- low noise
- sufficient CPU capacity
- 32 GB of memory
- 1 TB of local storage
- availability on the refurbished market
- the possibility of purchasing another matching system later

I considered buying two smaller 16 GB systems immediately. However, each 16 GB configuration cost approximately €300, while the 32 GB and 1 TB configuration cost €385.

Starting with one better-equipped node therefore provides more immediate capacity and better value. A second similarly configured node can be added later.

## Intended role

The system will initially act as the primary virtualization host.

The planned hypervisor is Proxmox VE.

Potential workloads include:

- Active Directory Domain Services
- Windows client systems
- Linux servers
- Docker containers
- Kubernetes nodes
- CI/CD runners
- centralized logging
- monitoring systems
- vulnerable test systems
- honeypot services

Kali Linux will not run on the server. It will remain on my laptop, which will act as an external administration and security-testing workstation.

## Long-term objective

The lab is intended to grow into a small multi-node environment.

Future additions may include:

- a second Dell OptiPlex Micro
- a managed VLAN-capable switch
- a compact 10-inch rack
- dedicated mini-PC rack mounts
- short Cat6 cables
- external backup storage
- a UPS
- a dedicated firewall or router
- a small status display

## Current limitations

At this stage:

- the hardware has not arrived
- the exact SSD model is unknown
- the physical condition has not been inspected
- the BIOS configuration is unknown
- Proxmox has not been installed
- no network architecture has been finalized
- no benchmark or power-consumption data is available

These details will be documented after delivery.

## Next steps

Once the system arrives:

1. Inspect the case and ports
2. Verify the CPU, memory and storage
3. Check the SSD health
4. Check for BIOS passwords or management locks
5. Update the BIOS if necessary
6. Enable virtualization features
7. Run basic memory and storage tests
8. Record idle power consumption if possible
9. Install Proxmox VE
10. Create the first test virtual machine

## Closing note

The home lab currently consists of one ordered corporate office refugee and a suspiciously ambitious roadmap.

A beginning is a beginning.