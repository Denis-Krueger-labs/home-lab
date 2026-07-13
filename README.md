# Home Lab

> Building a tiny data center one component at a time.

This repository documents the design, construction and evolution of my personal home lab.

The lab is intended for practical learning in:

- virtualization
- Active Directory
- Linux and Windows administration
- Kubernetes
- CI/CD
- network segmentation
- monitoring and logging
- defensive security
- authorized security testing

Rather than presenting only the finished environment, this repository records hardware purchases, architectural decisions, configuration changes, failures and lessons learned throughout the project.

## Current status

**Phase 1: Initial hardware acquisition**

The first virtualization node has been purchased and is currently awaiting delivery.

## First node

| Component | Specification |
|---|---|
| Model | Dell OptiPlex 5070 Micro |
| Processor | Intel Core i5-9500T |
| CPU | 6 cores / 6 threads |
| Memory | 32 GB RAM |
| Storage | 1 TB SSD |
| Network | 1× Gigabit Ethernet |
| Status | Purchased, awaiting delivery |

## Planned environment

The first node is intended to host infrastructure and target systems such as:

- Windows Server with Active Directory Domain Services
- domain-joined Windows clients
- Linux servers
- Docker workloads
- a virtual Kubernetes environment
- CI/CD runners
- monitoring and logging systems
- intentionally vulnerable machines
- honeypot services

Kali Linux will remain on my laptop and act as the external testing workstation.

## Documentation

- [Logbook](logbook/)
- [Hardware inventory](docs/hardware-inventory.md)
- [Roadmap](docs/roadmap.md)

## Disclaimer

This environment is intended exclusively for authorized education, experimentation and security research. Vulnerable services and offensive-security tools will only be used in isolated systems owned and controlled by the author.