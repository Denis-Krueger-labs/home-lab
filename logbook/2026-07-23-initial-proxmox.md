# Proxmox Installation and Home Lab v1.0

**Date:** 23 July 2026  
**System:** Dell OptiPlex 5070 Micro  
**Hardware:** 32 GB RAM, 1 TB SSD  
**Installed system:** Proxmox VE 9.2  
**Goal:** Install Proxmox, make sure the system can be managed remotely, and define what I actually want to build with the home lab.

## 1. Why I Built the Home Lab

The main reason for this home lab is simple: I wanted my own system where I can build things, break things, reinstall things, and learn without having to worry about ruining my main computer.

The lab will be used for several different areas:

* Proxmox and virtualization,
* Windows Server and Active Directory,
* Linux servers,
* Docker and self-hosted services,
* monitoring and logging,
* network segmentation,
* backup and recovery,
* and security testing.

It will also be useful as a smaller version of the kind of environment I may later work with at the TTZ. I can test ideas at home first, understand how they behave, and document what worked before trying to build something larger.

At the same time, the lab is not only for university or security work.

I also want to use it for personal projects, strange ideas, small services, dashboards, Linux experiments, and anything else that looks interesting enough to try.

Not every VM needs a serious purpose. Some systems will exist because they are useful, some because they teach me something, and some because I simply wanted to see whether I could make them work.

## 2. General Design

The Dell acts as the main infrastructure system.

It runs Proxmox and hosts the virtual machines and containers used by the lab.

The Dell is not supposed to be the attacking system. I do not plan to install a permanent Kali Linux VM on it.

When I need an attacker system for a security test, I can use:

* my laptop,
* another physical system,
* a temporary external machine,
* or later the TTZ environment.

This keeps the roles clearer.

The Dell hosts the services, clients, targets, logs, and backups. The attacker connects from outside when needed.

## 3. Installation Preparation

Before starting the installation, I connected:

* a monitor,
* a keyboard,
* an Ethernet cable,
* and the SanDisk Ultra 32 GB USB drive containing the installer.

The Dell already contained the internal 1 TB SSD.

The Samsung Portable SSD T3 was left disconnected during installation so I could not accidentally select it as the installation target.

The Proxmox ISO used for the installation was:

```text
proxmox-ve_9.2-1.iso
```

I wrote the ISO to the USB drive using Rufus.

The USB drive was only used to start the installer. Proxmox itself was installed on the internal SSD.

## 4. Booting the Installer

I opened the Dell boot menu using the F12 key.

At first, the USB drive did not appear as a boot option.

I tried the following steps:

1. Shut down the Dell.
2. Removed and reinserted the USB drive.
3. Tried another USB port.
4. Opened the boot menu again.
5. Checked that USB boot was enabled.
6. Selected the SanDisk drive as the UEFI boot device.

After changing the USB port, the Proxmox installer started correctly.

## 5. Proxmox Installation

I selected the graphical installer.

The internal 1 TB SSD was selected as the target drive.

I used the normal single-disk setup.

I did not use ZFS because the system currently has only one internal SSD. For the first version of the lab, a normal single-disk installation is easier to manage and completely sufficient.

The location, timezone, and keyboard settings were configured for Germany.

I also created the root password and entered an email address for administrative messages.

## 6. Network Configuration

The Ethernet interface was used as the management interface.

The installer suggested the following values:

```text
Hostname:   pve.fritz.box
IP address: 192.168.178.53/24
Gateway:    192.168.178.1
DNS server: 192.168.178.1
```

I kept these values.

The Proxmox web interface is available at:

```text
https://192.168.178.53:8006
```

The static IP makes it easier to reach the system because the address does not change every time the Dell restarts.

If the Dell is moved to another network, the address may need to be changed manually.

The relevant configuration files are:

```text
/etc/network/interfaces
/etc/hosts
```

## 7. First Boot

After the installation finished, I removed the USB drive and restarted the Dell.

Proxmox booted from the internal SSD.

The local screen showed:

```text
pve login:
```

The local administrator account is:

```text
root
```

After the system finished booting, I opened the Proxmox web interface from my main PC.

The login used:

```text
Username: root
Realm:    Linux PAM authentication
```

The browser showed a certificate warning because Proxmox uses a self-signed certificate after a fresh installation.

This was expected.

The web interface opened successfully.

## 8. Installation Result

The Proxmox node appeared in the web interface as:

```text
Datacenter
└── pve
```

The system was reachable through the local network and the dashboard displayed the expected hardware and system information.

The basic Proxmox installation was successful.

## 9. Current Status

| Component | Status |
|---|---|
| Dell OptiPlex 5070 Micro | Functional |
| 32 GB RAM | Recognized |
| Internal 1 TB SSD | Functional |
| Ethernet connection | Functional |
| Proxmox VE 9.2 | Installed |
| Local console | Accessible |
| Web interface | Accessible |
| Static IP address | Configured |
| Samsung backup SSD | Not configured yet |
| Virtual machines | Not created yet |
| Containers | Not created yet |

## 10. Repository Warning

After installation, the package update showed an error related to the Proxmox enterprise repository.

This is expected because the enterprise repository requires a paid subscription.

The next step is to:

1. disable the enterprise repository,
2. enable the no-subscription repository,
3. update the package lists,
4. install the available updates,
5. and restart the Dell.

The repository warning does not mean that the installation failed.

## 11. Backup Plan

The Samsung Portable SSD T3 will be used as the external backup drive.

The first backup plan is:

```text
Backup schedule: Once per week
Retention:       Keep the last 3 backups
Backup target:   Samsung Portable SSD T3
Backup mode:     Snapshot where possible
```

I also want to create manual backups before larger changes.

Examples include:

* Proxmox updates,
* network changes,
* Active Directory changes,
* security tests,
* major service deployments,
* and anything else that may be annoying to rebuild.

The backups should stay on the external SSD and not only on the internal drive.

## 12. Planned Lab Structure

The current plan looks like this:

```text
Dell OptiPlex 5070 Micro
└── Proxmox VE
    ├── Windows Server
    │   ├── Active Directory
    │   └── DNS
    │
    ├── Windows 11 Client
    │   └── Domain-joined workstation
    │
    ├── Debian Server
    │   ├── Docker
    │   ├── Docker Compose
    │   ├── Reverse proxy
    │   └── Self-hosted services
    │
    ├── Monitoring Server
    │   ├── Grafana
    │   ├── Prometheus
    │   └── Logging
    │
    ├── OPNsense
    │   └── Routing and network separation
    │
    └── Temporary Systems
        ├── Linux test VMs
        ├── Windows test VMs
        ├── Containers
        └── Project-specific systems
```

Not every system will run at the same time.

The exact setup will depend on what I am currently working on.

## 13. Planned Virtual Machines

### 13.1 Windows Server

The Windows Server VM will be used for:

* Active Directory Domain Services,
* DNS,
* user accounts,
* groups,
* Group Policy,
* and authentication tests.

Planned resources:

```text
vCPU: 2
RAM:  6 GB
Disk: 80 GB
```

### 13.2 Windows 11 Client

The Windows 11 VM will be used as a domain-joined workstation.

It will be useful for:

* testing logins,
* Group Policy,
* Windows event logs,
* software deployment,
* and later security tests.

Planned resources:

```text
vCPU: 2 to 4
RAM:  6 GB
Disk: 80 GB
```

### 13.3 Debian Server

The Debian server will run most of the normal services.

Planned tasks include:

* Docker,
* Docker Compose,
* a reverse proxy,
* internal tools,
* dashboards,
* and self-hosted applications.

Planned resources:

```text
vCPU: 2
RAM:  4 GB
Disk: 80 GB
```

### 13.4 Monitoring Server

The monitoring server will collect system information and logs.

Possible services include:

* Grafana,
* Prometheus,
* Loki,
* and later Wazuh.

Planned resources:

```text
vCPU: 2
RAM:  4 GB
Disk: 80 GB
```

### 13.5 OPNsense

OPNsense will later be used for:

* virtual routing,
* firewall rules,
* isolated networks,
* and segmentation tests.

Planned resources:

```text
vCPU: 2
RAM:  2 GB
Disk: 16 GB
```

### 13.6 Temporary Systems

Temporary systems can be created whenever they are needed.

Examples include:

* Linux test servers,
* disposable Windows VMs,
* NixOS experiments,
* development systems,
* vulnerable targets,
* project servers,
* and containers.

These systems do not need to exist permanently.

Before destructive testing, I will create snapshots or backups so they can be restored afterwards.

## 14. Build Plan

### Phase 1: Finish Proxmox Setup

1. Disable the enterprise repository.
2. Enable the no-subscription repository.
3. Install updates.
4. Restart the Dell.
5. Check that the node is healthy.
6. Reserve the IP address in the FRITZ!Box.

### Phase 2: Configure Backups

1. Connect the Samsung external SSD.
2. Format and mount it.
3. Add it as backup storage in Proxmox.
4. Create a weekly backup job.
5. Keep the last three backups.
6. Test a backup.
7. Test a restore.

### Phase 3: Create the First Debian VM

1. Download Debian.
2. Upload the ISO to Proxmox.
3. Create the VM.
4. Install Debian.
5. Configure SSH.
6. Install the QEMU guest agent.
7. Create a clean snapshot.
8. Turn the VM into a reusable template.

### Phase 4: Build Active Directory

1. Create the Windows Server VM.
2. Install Windows Server.
3. Install Active Directory Domain Services.
4. Configure DNS.
5. Create users and groups.
6. Create the Windows 11 VM.
7. Join it to the domain.
8. Test logins and Group Policy.

### Phase 5: Add Linux Services

1. Create the Debian infrastructure server.
2. Install Docker.
3. Install Docker Compose.
4. Deploy a reverse proxy.
5. Add the first self-hosted service.
6. Document the ports and addresses.

### Phase 6: Add Monitoring

1. Create the monitoring server.
2. Collect Proxmox metrics.
3. Collect Linux metrics.
4. Collect Windows logs.
5. Build the first dashboard.
6. Test alerts.

### Phase 7: Add Network Separation

1. Create the OPNsense VM.
2. Build an isolated lab network.
3. Separate management, servers, clients, and test systems.
4. Configure firewall rules.
5. Check that isolated systems cannot reach the home network.
6. Document the network layout.

### Phase 8: Run a Security Test

1. Create a vulnerable or intentionally misconfigured target.
2. Place it inside the isolated network.
3. Create a clean snapshot.
4. Connect from an external testing system.
5. Perform a controlled test.
6. Check the logs and network traffic.
7. Restore the target.
8. Document what happened.

## 15. What Counts as Home Lab v1.0

Home Lab v1.0 is complete when:

1. Proxmox is updated and stable.
2. The external backup drive is configured.
3. Automatic backups work.
4. A restore has been tested.
5. A Debian template exists.
6. Active Directory works.
7. A Windows client is joined to the domain.
8. Docker services are running.
9. Monitoring and logging work.
10. An isolated test network exists.
11. A controlled security test has been completed.
12. The lab is documented.
13. I can also use it for my own projects without rebuilding everything every time.

## 16. Things I Am Not Building Yet

The following parts are not planned for the first version:

* multiple Proxmox nodes,
* high availability,
* Ceph,
* ZFS replication,
* a full Kubernetes cluster,
* a permanent Kali VM,
* a permanent malware lab,
* public production services,
* and the complete TTZ environment.

These can be added later if they become useful.

## 17. Lessons Learned

The installation worked, but it also showed why it is useful to take things one step at a time.

Testing the hardware first meant that the memory problem was already solved before installing Proxmox.

Disconnecting the backup SSD avoided the risk of selecting the wrong disk.

Using a static IP made the web interface easy to find.

The USB boot problem was also a good reminder that a setup can fail for a very small reason, even when the installer itself is fine.

The Dell is now ready to become the base of the home lab.

The next step is to finish the Proxmox configuration and then create the first Debian VM.
