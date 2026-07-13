# Home Lab Roadmap

This roadmap describes the intended development of the home lab. It may change as hardware limitations, costs and learning priorities become clearer.

## Phase 1: First node

- [x] Select initial hardware
- [x] Purchase first compute node
- [ ] Receive and inspect the system
- [ ] Verify hardware specifications
- [ ] Test memory and storage
- [ ] Install Proxmox VE
- [ ] Configure the management network
- [ ] Create the first Linux virtual machine
- [ ] Establish a backup process

## Phase 2: Core infrastructure

- [ ] Deploy Windows Server
- [ ] Configure Active Directory Domain Services
- [ ] Deploy a domain-joined Windows client
- [ ] Deploy Linux infrastructure services
- [ ] Document naming and addressing conventions
- [ ] Create reusable VM templates

## Phase 3: Networking

- [ ] Purchase a managed switch
- [ ] Design VLAN structure
- [ ] Separate management, server and test networks
- [ ] Configure firewall rules
- [ ] Connect the external Kali workstation
- [ ] Validate network isolation

## Phase 4: Containers and automation

- [ ] Deploy Docker workloads
- [ ] Build a Kubernetes test environment
- [ ] Configure a CI/CD runner
- [ ] Introduce Ansible or another automation tool
- [ ] Store reusable configurations in the repository

## Phase 5: Monitoring and security

- [ ] Deploy centralized logging
- [ ] Add infrastructure monitoring
- [ ] Create alerting rules
- [ ] Deploy intentionally vulnerable targets
- [ ] Build an isolated honeypot environment
- [ ] Document attack and detection exercises

## Phase 6: Physical expansion

- [ ] Purchase a second compute node
- [ ] Purchase a compact rack
- [ ] Add mini-PC mounting hardware
- [ ] Add structured cabling
- [ ] Add a UPS
- [ ] Add external backup storage

## Long-term ideas

- multi-node Kubernetes
- physical node failure testing
- Active Directory attack and defence exercises
- automated infrastructure deployment
- centralized identity and secrets management
- dedicated firewall appliance
- honeypot visualization
- Mori status display