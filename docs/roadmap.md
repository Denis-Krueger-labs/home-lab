# Home Lab Roadmap

This roadmap describes the current plan for the home lab.

It is not fixed forever. Tasks may move when hardware limitations, costs, project ideas, or learning priorities change.

The lab has two purposes:

1. Build a useful infrastructure and security environment.
2. Provide a place for personal projects, experiments, and unnecessary technical nonsense.

## Phase 1: First Node and Proxmox Foundation

- [x] Select the initial hardware
- [x] Purchase the first compute node
- [x] Receive and inspect the system
- [x] Verify the hardware specifications
- [x] Test the memory and storage
- [x] Diagnose the defective RAM module
- [x] Return the system for repair or replacement
- [x] Confirm that the repaired system recognizes 32 GB RAM
- [x] Record the initial hardware baseline
- [x] Install Proxmox VE 9.2
- [x] Configure the management network
- [x] Configure the no-subscription repository
- [x] Install all available Proxmox updates
- [x] Verify a healthy reboot
- [x] Configure the external backup drive
- [x] Create an automatic weekly backup job
- [x] Upload the Debian 13 installation ISO
- [x] Create the first Debian virtual machine
- [x] Install and configure the QEMU guest agent
- [x] Install and configure Cloud-Init
- [x] Create a reusable Debian server template
- [ ] Create the first manual VM backup
- [ ] Restore a VM from backup
- [ ] Confirm that the automatic backup retention works

## Phase 2: Windows Templates and Core Infrastructure

### Windows Server Template

- [ ] Download the Windows Server installation ISO
- [ ] Download the VirtIO driver ISO
- [ ] Create the Windows Server base VM
- [ ] Configure UEFI and virtual hardware
- [ ] Install Windows Server
- [ ] Install VirtIO drivers
- [ ] Install the QEMU guest agent
- [ ] Install all Windows updates
- [ ] Configure the local administrator account
- [ ] Prepare the system for cloning
- [ ] Convert the clean system into a reusable template
- [ ] Test a full clone of the Windows Server template

### Active Directory

- [ ] Clone the Windows Server template as `dc01`
- [ ] Assign a static IP address
- [ ] Choose the internal domain namespace
- [ ] Install Active Directory Domain Services
- [ ] Configure DNS
- [ ] Create the first organizational units
- [ ] Create test users and groups
- [ ] Create the first Group Policy
- [ ] Document the domain structure

### Windows Client

- [ ] Download the Windows 11 installation ISO
- [ ] Create a Windows 11 base VM
- [ ] Install VirtIO drivers
- [ ] Install the QEMU guest agent
- [ ] Install all updates
- [ ] Create a reusable Windows 11 template
- [ ] Clone the template as `client01`
- [ ] Join `client01` to the domain
- [ ] Test domain authentication
- [ ] Test Group Policy application

## Phase 3: Linux Infrastructure

- [ ] Clone the Debian template as `docker01`
- [ ] Test Cloud-Init on the first clone
- [ ] Confirm that the clone receives a unique machine ID
- [ ] Confirm that the clone receives unique SSH host keys
- [ ] Assign the final hostname
- [ ] Configure a static or reserved IP address
- [ ] Expand CPU, memory, and storage if required
- [ ] Install Docker
- [ ] Install Docker Compose
- [ ] Deploy the first containerized service
- [ ] Deploy a reverse proxy
- [ ] Add a simple internal dashboard
- [ ] Document all deployed services and ports
- [ ] Back up and restore the first Linux infrastructure server

## Phase 4: Naming, Addressing, and Documentation

- [ ] Create `docs/architecture.md`
- [ ] Create `docs/network-plan.md`
- [ ] Create `docs/naming-conventions.md`
- [ ] Create `docs/backup-and-recovery.md`
- [ ] Create `docs/vm-template.md`
- [ ] Create `docs/decisions.md`
- [ ] Define VM ID ranges
- [ ] Define hostname conventions
- [ ] Define static IP assignments
- [ ] Define service naming rules
- [ ] Document which systems are permanent and which are temporary
- [ ] Update the hardware inventory
- [ ] Keep the README current

## Phase 5: Monitoring and Logging

- [ ] Create the monitoring server
- [ ] Collect Proxmox host metrics
- [ ] Collect Debian server metrics
- [ ] Collect Windows Server events
- [ ] Collect Windows client events
- [ ] Deploy Grafana
- [ ] Deploy Prometheus
- [ ] Deploy Loki or another log platform
- [ ] Evaluate Wazuh for security monitoring
- [ ] Build the first useful dashboard
- [ ] Create basic alerting rules
- [ ] Test whether an alert is actually delivered
- [ ] Document the monitoring architecture

## Phase 6: Networking and Isolation

- [ ] Purchase a managed switch
- [ ] Design the VLAN structure
- [ ] Separate management systems
- [ ] Separate infrastructure servers
- [ ] Separate Windows clients
- [ ] Create an isolated test network
- [ ] Create a route for the external testing system
- [ ] Deploy OPNsense or another virtual firewall
- [ ] Configure firewall rules
- [ ] Confirm that test systems cannot freely reach the home network
- [ ] Confirm that management access still works
- [ ] Document the final network layout

## Phase 7: Controlled Security Testing

- [ ] Create an intentionally vulnerable target
- [ ] Place the target in the isolated test network
- [ ] Create a clean snapshot
- [ ] Connect from an external testing system
- [ ] Perform a controlled attack
- [ ] Observe the generated logs and alerts
- [ ] Restore the target
- [ ] Confirm that the restored target works
- [ ] Document the complete attack and recovery process

The Dell will host the infrastructure, services, targets, clients, monitoring, and recovery systems.

The attacker system will remain external. No permanent Kali VM is planned for the Proxmox host.

## Phase 8: Containers and Automation

- [ ] Add reusable Docker Compose files to the repository
- [ ] Configure a CI/CD runner
- [ ] Introduce Ansible or another automation tool
- [ ] Automate the setup of Debian clones
- [ ] Automate common package installation
- [ ] Automate monitoring-agent deployment
- [ ] Store sanitized reusable configurations in the repository
- [ ] Document secret-management rules
- [ ] Build a small Kubernetes test environment
- [ ] Decide whether Kubernetes is useful enough to keep

Kubernetes is a later learning project, not a requirement for the first working version of the lab.

## Phase 9: Personal and Experimental Projects

- [ ] Deploy a Mori-themed status dashboard
- [ ] Create a small service-status display
- [ ] Test NixOS in a VM
- [ ] Host personal development tools
- [ ] Test ReportForge Sec inside the lab
- [ ] Create temporary project servers
- [ ] Experiment with unusual Linux configurations
- [ ] Build something completely unnecessary because it looked fun

These projects are part of the purpose of the lab and do not need to justify themselves as university or career work.

## Phase 10: Physical Expansion

- [ ] Decide whether a second compute node is useful
- [ ] Purchase a managed switch
- [ ] Purchase a compact rack
- [ ] Add mini-PC mounting hardware
- [ ] Add structured cabling
- [ ] Add a UPS
- [ ] Test workloads across multiple physical hosts
- [ ] Test physical node failure and recovery
- [ ] Evaluate Proxmox clustering
- [ ] Evaluate shared storage only if multiple nodes exist

## Home Lab v1.0 Completion Criteria

Home Lab v1.0 will be considered complete when:

- [ ] Proxmox is updated and stable
- [ ] Automatic backups run successfully
- [ ] A backup restore has been tested
- [x] A reusable Debian template exists
- [ ] A reusable Windows Server template exists
- [ ] A reusable Windows client template exists
- [ ] Active Directory is operational
- [ ] A Windows client is joined to the domain
- [ ] A Debian infrastructure server is operational
- [ ] Docker workloads are running
- [ ] Monitoring and centralized logging are operational
- [ ] An isolated test network exists
- [ ] A controlled security test has been completed
- [ ] The environment can be restored after the test
- [ ] The architecture and procedures are documented
- [ ] The lab is usable for personal projects without rebuilding the foundation each time

## Long-Term Ideas

- multi-node Proxmox
- multi-node Kubernetes
- physical node failure testing
- Active Directory attack and defence exercises
- automated infrastructure deployment
- centralized identity management
- secrets management
- dedicated firewall hardware
- honeypot visualization
- Mori status display
- integration with the future TTZ security test environment
