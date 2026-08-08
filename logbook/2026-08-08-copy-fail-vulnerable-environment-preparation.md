# Copy Fail Vulnerable Environment Preparation

**Date:** 8 August 2026  
**Platform:** Proxmox VE 9.2.5  
**Guest OS:** Ubuntu Server 24.04 LTS  
**Research target:** CVE-2026-31431, Copy Fail  
**Environment:** Isolated laboratory network behind OPNsense  
**Goal:** Preserve a patched reference system, construct a controlled pre-fix Copy Fail test system, verify the required kernel interface from an unprivileged account, and prepare the official proof of concept for later analysis without executing it.

> Public documentation intentionally omits management addresses, overlay-network identities, MAC addresses, machine IDs, filesystem UUIDs, credentials, and other unnecessary infrastructure identifiers.

---

## 1. Starting Point

The previous lab checkpoint established routed administrative access to the isolated laboratory network.

The relevant architecture remained:

```text
trusted management path
        |
        v
Proxmox VE
        |
        v
OPNsense
        |
        v
isolated laboratory network
        |
        +-- patched Copy Fail reference system
```

A dedicated Ubuntu Server virtual machine had already been created for the Copy Fail research project.

Before attempting to reproduce the vulnerability, the reference system was inspected to determine whether it was actually vulnerable.

The objective of this session was therefore not immediately to execute an exploit.

Instead, the process was:

```text
validate reference state
        ↓
preserve patched system
        ↓
clone isolated experiment system
        ↓
reconstruct historical kernel state
        ↓
separate vendor mitigation from kernel fix
        ↓
verify unprivileged AF_ALG access
        ↓
inspect PoC
        ↓
execute only after understanding it
```

---

## 2. Patched Reference Validation

The reference Ubuntu system was inspected before any modification.

The running kernel was:

```text
6.8.0-137-generic
```

The installed image package was:

```text
6.8.0-137.137
```

The installed `kmod` package was:

```text
31+20240202-2ubuntu7.2
```

The kernel configuration contained:

```text
CONFIG_CRYPTO_USER_API=m
CONFIG_CRYPTO_USER_API_HASH=m
CONFIG_CRYPTO_USER_API_SKCIPHER=m
CONFIG_CRYPTO_USER_API_RNG=m
CONFIG_CRYPTO_USER_API_AEAD=m
```

This confirmed that the user-space kernel crypto API, including AEAD support, existed in the kernel configuration.

The module itself was present:

```text
/lib/modules/<running-kernel>/kernel/crypto/algif_aead.ko.zst
```

However, the following mitigation file was also present:

```text
/etc/modprobe.d/disable-algif_aead.conf
```

Its relevant configuration was:

```text
install algif_aead /bin/false
```

A dry-run confirmed the effect:

```bash
sudo modprobe -n -v algif_aead
```

The resulting sequence attempted to load the dependency but replaced the `algif_aead` module load with:

```text
install /bin/false
```

The module was also not currently loaded.

### Result

The reference system was protected by two independent mechanisms:

```text
1. patched kernel
2. vendor-provided algif_aead module mitigation
```

It was therefore unsuitable as the vulnerable reproduction target.

Rather than downgrading the reference system in place, it was preserved as the future patched comparison system.

---

## 3. Evidence Collection and Sanitization

Evidence from the reference validation was stored separately from the written report.

The evidence set contained:

```text
01-running-kernel.txt
02-package-versions.txt
03-algif-aead-modinfo.txt
04-kernel-config.txt
05-modprobe-config.txt
06-modprobe-dry-run.txt
07-module-loaded.txt
```

The module-loaded output was intentionally empty because `algif_aead` was not loaded.

Corresponding screenshots were also prepared.

A public checksum manifest was generated and verified.

The workflow used for evidence handling was:

```text
collect raw evidence
        ↓
hash raw evidence
        ↓
preserve raw copy privately
        ↓
sanitize public copy
        ↓
hash sanitized copy
        ↓
commit only sanitized evidence
```

Machine identifiers, boot identifiers, MAC addresses, management addresses, workstation paths, and similar infrastructure details were removed from the public evidence.

This keeps the public repository useful for reproducibility without unnecessarily publishing home-network metadata.

---

## 4. Creation of the Vulnerable Experimental Clone

A full clone of the patched reference VM was created.

The design became:

```text
patched reference
      |
      | full clone
      v
experimental Copy Fail VM
```

Only the experimental clone was started while its identity was being corrected.

This was important because the clone initially inherited several values from the source VM.

Initial inspection showed that it still had:

```text
original hostname
original machine ID
original DHCP identity
```

This also resulted in the clone initially receiving the same address that had previously been associated with the reference system.

The source VM remained powered off during this stage to prevent an address or identity collision.

---

## 5. Clone Identity Separation

The clone was renamed:

```text
copyfail-vuln
```

The hostname entry in `/etc/hosts` was updated accordingly.

The inherited machine ID was removed and regenerated:

```bash
sudo rm -f /etc/machine-id
sudo systemd-machine-id-setup
```

The new machine ID was confirmed to differ from the source.

SSH host keys were also regenerated so that the clone did not share the cryptographic host identity of the reference VM.

After rebooting, the clone received a separate DHCP lease.

The resulting systems therefore had independent:

```text
hostname
machine ID
SSH host keys
network identity
```

This allowed the reference and experimental systems to coexist safely later.

---

## 6. SSH Service Issue After Cloning

Remote SSH access initially failed.

The first assumption was that the network firewall was blocking the new clone.

However, inspection from the Proxmox console showed:

```bash
systemctl is-active ssh
```

returned:

```text
inactive
```

The SSH service was therefore enabled and started:

```bash
sudo systemctl enable --now ssh
```

The service then reported:

```text
active
```

and TCP port 22 was confirmed to be listening.

Despite this, remote SSH access still timed out.

This demonstrated that two independent issues had been present:

```text
1. SSH was initially not running.
2. network access was still blocked after SSH was fixed.
```

---

## 7. Network Path Troubleshooting

The Proxmox host already contained the expected route toward the isolated laboratory subnet.

A route lookup showed that traffic for the experimental VM was forwarded through OPNsense as intended.

Conceptually:

```text
Proxmox
   |
   | route for <LAB_SUBNET>
   v
OPNsense
   |
   v
experimental VM
```

However, a TCP connection test from Proxmox to the clone still failed.

The OPNsense live firewall log then showed that the connection was being rejected by the default deny policy.

The existing SSH rule was inspected.

It permitted:

```text
trusted management source
        ↓
TCP/22
        ↓
one specific laboratory host
```

The rule had been created for the original Copy Fail reference system and contained its individual DHCP address as the destination.

The newly cloned VM therefore correctly failed to match the allow rule.

---

## 8. Firewall Rule Generalization

Three possible approaches were considered:

| Approach | Advantage | Disadvantage |
|---|---|---|
| Individual host rule | Strong destination-level least privilege | Brittle with DHCP and frequent clones |
| Host alias | Maintains explicit allowlist | Requires continuing alias maintenance |
| Laboratory subnet | Stable for dynamic test VMs | Larger set of possible SSH targets |

For this experimental environment, the subnet-scoped approach was selected.

The resulting policy is conceptually:

```text
trusted management source
        ↓
TCP port 22 only
        ↓
isolated laboratory subnet
```

The rule does not expose arbitrary services and does not make the laboratory network publicly reachable.

Only the destination scope was broadened.

The source remains restricted to the trusted management path and the permitted service remains SSH.

After applying the rule, the experimental VM became reachable successfully.

### Security Tradeoff

This change increases the number of laboratory systems that may receive SSH connections from the permitted management source.

A system newly created inside the laboratory subnet with SSH enabled will also match the firewall rule.

However, the environment regularly creates, clones, destroys, and restores experimental systems.

Binding the rule to transient DHCP leases therefore created unnecessary operational coupling and had already caused a reproducibility problem.

For this laboratory, the subnet-scoped rule was considered an acceptable tradeoff between:

```text
least privilege
and
repeatable administration
```

A more static production environment would generally benefit from explicit administrative target allowlists.

---

## 9. Hypervisor Trust Boundary

The troubleshooting also highlighted that the virtualization host forms a significantly stronger trust boundary than the individual guest systems.

Possession of network access to a guest is not equivalent to administrative control of the hypervisor.

The virtualization management plane is not intentionally exposed directly to the public Internet and is accessed only through trusted management paths.

Further control-plane hardening is tracked separately from the Copy Fail experiment.

Exact authentication mechanisms, management addresses, firewall layout, and remaining hardening tasks are intentionally not documented in the public report.

The important architectural principle is:

```text
deliberately vulnerable guest
        ≠
deliberately vulnerable hypervisor
```

The vulnerable Copy Fail machine remains an expendable experimental system.

The hypervisor does not form part of the vulnerability reproduction target.

---

## 10. Historical Kernel Package Discovery

The patched reference system was running:

```text
6.8.0-137-generic
```

The target historical kernel for reproduction was:

```text
6.8.0-116-generic
6.8.0-116.116
```

Initially:

```bash
apt-cache policy linux-image-6.8.0-116-generic
```

returned:

```text
Unable to locate package
```

The currently configured repositories contained:

```text
noble
noble-updates
noble-backports
noble-security
```

but not:

```text
noble-proposed
```

The historical `6.8.0-116.116` package had been published through the proposed repository and was no longer available through the currently configured standard package indexes.

---

## 11. Ubuntu Archive Snapshot

Rather than obtaining an old kernel from an unofficial mirror, the Ubuntu archive snapshot infrastructure was used.

A temporary APT source was added for the historical `noble-proposed` state using the snapshot timestamp:

```text
20260425T120000Z
```

After refreshing package metadata:

```bash
apt policy linux-image-6.8.0-116-generic
```

returned:

```text
Installed: (none)
Candidate: 6.8.0-116.116
```

with the package resolving through:

```text
snapshot.ubuntu.com
noble-proposed/main
```

The matching module packages were also available:

```text
linux-modules-6.8.0-116-generic
6.8.0-116.116

linux-modules-extra-6.8.0-116-generic
6.8.0-116.116
```

This created a reproducible and vendor-backed method of reconstructing the historical system state.

---

## 12. Locating `algif_aead`

Before installing the historical kernel, the relevant module packages were downloaded for inspection.

The packages were not installed at this stage.

The contents were inspected using:

```bash
dpkg-deb -c <package>
```

The required module was found inside:

```text
linux-modules-6.8.0-116-generic_6.8.0-116.116_amd64.deb
```

at:

```text
/lib/modules/6.8.0-116-generic/kernel/crypto/algif_aead.ko.zst
```

It was not located in `linux-modules-extra`.

This proved that the normal historical modules package already contained the functionality required for Copy Fail.

---

## 13. Simulated Historical Kernel Installation

Before modifying the system, APT was instructed to simulate the installation:

```bash
sudo apt-get -s install --no-install-recommends \
  linux-image-6.8.0-116-generic=6.8.0-116.116 \
  linux-modules-6.8.0-116-generic=6.8.0-116.116
```

The result was:

```text
0 upgraded
2 newly installed
0 removed
77 not upgraded
```

Only the requested versioned packages would be added.

No unrelated packages from `noble-proposed` would be upgraded.

This was particularly important because the purpose of the experiment was to change one controlled variable rather than accidentally convert the entire VM into a proposed-package test system.

---

## 14. Historical Kernel Installation

The exact packages were then installed:

```text
linux-image-6.8.0-116-generic
linux-modules-6.8.0-116-generic
```

both at:

```text
6.8.0-116.116
```

The existing patched kernel remained installed.

The system therefore temporarily contained both:

```text
6.8.0-137-generic
6.8.0-116-generic
```

This provided a known-good recovery kernel while allowing the historical system state to be tested.

The historical kernel image and generated initramfs were both verified under `/boot`.

---

## 15. Controlled One-Time GRUB Boot

GRUB contained a valid advanced boot entry for:

```text
Ubuntu, with Linux 6.8.0-116-generic
```

The normal configuration remained:

```text
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=0
```

The historical kernel was deliberately selected using a one-time GRUB boot entry.

The permanent default was not changed.

The intended behavior was:

```text
next boot:
6.8.0-116-generic

later normal boot:
default patched kernel
```

The `next_entry` value was verified before rebooting.

After reboot:

```bash
uname -r
```

returned:

```text
6.8.0-116-generic
```

and the one-time GRUB entry had been consumed.

The experimental VM was therefore running the intended historical kernel while retaining the patched kernel as the normal fallback.

---

## 16. Broken Proxmox Console After Historical Boot

After booting the historical kernel, the graphical Proxmox console became heavily corrupted.

SSH remained functional and the system otherwise booted correctly.

PCI inspection showed:

```text
VGA compatible controller: Device [1234:1111]
Subsystem: Red Hat, Inc. QEMU Virtual Machine
```

but initially no kernel graphics driver was bound to the virtual VGA device.

The historical kernel had intentionally been installed using the minimal package set.

The previously downloaded `linux-modules-extra` package was therefore inspected.

It contained:

```text
drivers/gpu/drm/tiny/bochs.ko.zst
```

and:

```text
drivers/gpu/drm/qxl/qxl.ko.zst
```

The QEMU VGA device required the Bochs DRM support.

---

## 17. The `modules-extra` Mistake

An initial attempt was made to load:

```bash
sudo modprobe bochs
```

This failed:

```text
FATAL: Module bochs not found in directory /lib/modules/6.8.0-116-generic
```

The mistake was straightforward:

```text
the package had been downloaded and inspected
but had not actually been installed
```

Inspecting a `.deb` with:

```bash
dpkg-deb -c
```

does not install its contents.

The exact matching package was subsequently installed:

```text
linux-modules-extra-6.8.0-116-generic
6.8.0-116.116
```

The driver then became available.

After loading it:

```bash
sudo modprobe bochs
```

PCI inspection showed:

```text
Kernel driver in use: bochs-drm
Kernel modules: bochs
```

### Result

The problem was not a failure of the historical kernel itself.

It was caused by constructing an unnecessarily minimal Ubuntu kernel environment that omitted the virtual graphics support package.

Installing the complete matching module set created a more faithful historical Ubuntu generic-kernel environment.

---

## 18. Vendor Mitigation Still Active

Even after booting the historical kernel, the system was not yet intentionally exposed to Copy Fail.

A dry run showed:

```bash
sudo modprobe -n -v algif_aead
```

returned:

```text
insmod .../af_alg.ko.zst
install /bin/false
```

The current `kmod` package still contained Canonical's separate mitigation:

```text
/etc/modprobe.d/disable-algif_aead.conf
```

with:

```text
install algif_aead /bin/false
```

This demonstrated an important distinction:

```text
historical pre-fix kernel
        +
current vendor mitigation
        =
still mitigated
```

The kernel version and the module mitigation therefore had to be treated as separate experimental variables.

---

## 19. Reversible Mitigation Removal

The mitigation file was not deleted.

Instead, it was renamed:

```text
disable-algif_aead.conf
        ↓
disable-algif_aead.conf.disabled
```

This kept the change:

```text
explicit
reversible
easy to document
```

A second dry-run was performed:

```bash
sudo modprobe -n -v algif_aead
```

The result changed to:

```text
insmod .../af_alg.ko.zst
insmod .../algif_aead.ko.zst
```

This confirmed that the vendor mitigation was no longer intercepting the module load.

The module was then loaded normally:

```bash
sudo modprobe algif_aead
```

Verification showed:

```text
algif_aead
af_alg
```

both loaded.

The experimental state had therefore changed from:

```text
pre-fix kernel + vendor mitigation
```

to:

```text
pre-fix kernel + accessible AF_ALG AEAD interface
```

---

## 20. Creation of an Unprivileged Test User

The existing research account has administrative capabilities and was therefore unsuitable for demonstrating a local privilege escalation.

A dedicated account was created:

```text
labuser
```

Its resulting identity was:

```text
uid=1001(labuser)
gid=1001(labuser)
groups=1001(labuser),100(users)
```

The account was not a member of:

```text
sudo
lxd
docker
adm
```

or another administrative group.

The experiment was then continued from:

```text
labuser
```

rather than the research account.

This establishes a clean privilege boundary for later reproduction.

---

## 21. Benign AF_ALG Capability Check

Before running exploit code, the available kernel crypto algorithms were inspected through:

```text
/proc/crypto
```

AEAD implementations included:

```text
gcm(aes)
rfc4106(gcm(aes))
```

A minimal Python program was then used to test whether an ordinary unprivileged user could bind to the AEAD interface:

```python
import socket

s = socket.socket(socket.AF_ALG, socket.SOCK_SEQPACKET, 0)
s.bind(("aead", "gcm(aes)"))

print("AF_ALG AEAD bind succeeded as unprivileged user")
s.close()
```

The bind succeeded.

This did not exploit CVE-2026-31431.

It only proved that:

```text
ordinary local user
        ↓
AF_ALG socket
        ↓
AEAD interface
        ↓
successful bind
```

The user remained:

```text
labuser
```

with its original UID.

This provides a clean pre-exploitation checkpoint.

---

## 22. Official PoC Acquisition

The official Copy Fail proof of concept was downloaded as an ordinary user.

It was saved locally rather than executing it directly through a shell pipeline.

The downloaded file was:

```text
731 bytes
```

with SHA-256:

```text
d401e7d1c00605749d6c617ace73ab20a762b72e41c2e1590331596e38219a61
```

This initially differed from the published checksum:

```text
a567d09b15f6e4440e70c9f2aa8edec8ed59f53301952df05c719aa3911687f9
```

The mismatch was investigated rather than ignored.

---

## 23. PoC Hash Mismatch

The difference was caused by a single trailing newline.

The downloaded representation contained:

```text
731 bytes
no newline after final line
```

Adding one final newline produced:

```text
732 bytes
```

and exactly the published SHA-256:

```text
a567d09b15f6e4440e70c9f2aa8edec8ed59f53301952df05c719aa3911687f9
```

The actual Python source was otherwise identical.

This was a useful reminder that:

```text
cryptographic hashes validate bytes
not semantic source-code equivalence
```

A visually identical text file may therefore have a different digest because of line-ending or end-of-file differences.

The mismatch was resolved before any execution was considered.

---

## 24. PoC Initial Inspection

The PoC is unusually small:

```text
10 physical lines
approximately 732 bytes in the published representation
```

However, the line count is misleading.

Several operations are compressed onto individual lines using:

```text
short variable names
semicolons
inline expressions
compressed binary data
```

The source imports only standard Python modules:

```python
os
zlib
socket
```

The initial structure was identified as:

```text
imports and byte helper
        ↓
4-byte write helper
        ↓
AF_ALG AEAD configuration
        ↓
splice target pages
        ↓
trigger crypto operation
        ↓
decompress small embedded payload
        ↓
apply payload in 4-byte chunks
        ↓
execute /usr/bin/su
```

No PoC execution was performed during this checkpoint.

The next stage is to expand and understand the source line by line before using it.

---

## 25. Current Experimental State

At the end of the session, the experimental VM has:

| Component | State |
|---|---|
| Separate clone identity | Working |
| Separate SSH host identity | Working |
| Separate DHCP identity | Working |
| Remote SSH administration | Working |
| OPNsense SSH policy | Generalized to lab subnet |
| Historical Ubuntu kernel | Installed |
| Historical kernel boot | Confirmed |
| Patched fallback kernel | Retained |
| Matching standard modules | Installed |
| Matching `modules-extra` | Installed |
| QEMU VGA driver | `bochs-drm` bound |
| `algif_aead` module | Present and loaded |
| `af_alg` module | Present and loaded |
| Canonical module mitigation | Deliberately disabled on experiment clone |
| Dedicated unprivileged user | Created |
| Unprivileged AEAD bind | Confirmed |
| Official PoC | Downloaded and inspected |
| PoC checksum discrepancy | Explained |
| PoC executed | **No** |
| Privilege escalation demonstrated | **No** |

The system should therefore currently be described as:

```text
pre-fix candidate environment prepared for controlled reproduction
```

rather than:

```text
confirmed vulnerable
```

Actual vulnerability confirmation still requires successful controlled reproduction.

---

## 26. Problems Encountered

Several useful mistakes and troubleshooting cases occurred during the session.

### 26.1 Clone Retained Source Identity

The full clone initially inherited:

```text
hostname
machine ID
network identity
```

The source VM was kept offline while the clone identity was regenerated.

### 26.2 SSH Was Not Running

Initial remote-access failure was partly caused by the SSH service being inactive.

This was identified locally before continuing with network troubleshooting.

### 26.3 Firewall Rule Was Too Specific

The existing OPNsense rule permitted SSH only to the original VM's individual address.

The clone obtained a new DHCP lease and was correctly rejected by the default-deny policy.

The rule was changed to a subnet-scoped destination while keeping the source and service restrictions.

### 26.4 Current Repositories Did Not Contain the Historical Kernel

The required package was not visible through the normal active Ubuntu repositories.

The Ubuntu snapshot archive was used instead of an unofficial binary source.

### 26.5 Minimal Kernel Installation Broke Console Graphics

The first historical installation omitted `linux-modules-extra`.

This removed the Bochs DRM driver required by the Proxmox virtual VGA device.

### 26.6 Downloading a Package Is Not Installing It

The missing driver was visible when inspecting the downloaded `.deb`, which initially led to an unsuccessful `modprobe`.

The package had only been downloaded.

After installing it, the driver loaded normally.

### 26.7 Historical Kernel Alone Was Not Enough

The system continued to contain Canonical's newer `kmod` mitigation.

The vulnerability interface therefore remained disabled until the mitigation configuration was intentionally and reversibly removed.

### 26.8 PoC Checksum Initially Appeared Incorrect

The downloaded source was one byte shorter than the published representation.

The difference was a trailing newline rather than a source-code modification.

---

## 27. Lessons Learned

A clone must be treated as a new machine rather than merely a copy of a disk.

Machine identity includes more than the hostname.

A firewall rule can be technically correct while still being operationally too tightly coupled to a transient address.

Default-deny logging is extremely useful when determining where a routed connection actually fails.

Network reachability, service availability, and service authentication are separate layers and should be tested independently.

A deliberately vulnerable guest should remain separated from the virtualization management plane.

Historical package reconstruction should use authoritative archive infrastructure where possible.

Exact package versions should be installed explicitly when reconstructing a vulnerability state.

APT simulation is useful before enabling historical or proposed package sources.

A historical kernel should be installed alongside a known-good kernel when possible rather than replacing the recovery path.

One-shot boot selection is safer than immediately changing the permanent boot default during remote testing.

Ubuntu's `linux-modules-extra` package may contain virtual hardware support that is unnecessary for the vulnerability itself but necessary for a normal guest environment.

A downloaded `.deb` is not equivalent to an installed package.

Kernel patch state and compensating distribution mitigations must be evaluated independently.

A privilege escalation should be demonstrated from a genuinely unprivileged account.

Testing a vulnerability prerequisite is not the same as exploiting the vulnerability.

A hash mismatch should be investigated at the byte level before concluding that a file has been modified.

Physical source-code line count says very little about exploit complexity when many operations are compressed onto individual lines.

Most importantly:

```text
do not execute a PoC merely because it is short
```

The next task is to understand why those ten lines interact with the Linux kernel in a way that can produce a controlled page-cache write.

---

## 28. Security and Documentation Notes

The laboratory contains intentionally weakened systems.

Public documentation therefore describes enough architecture to make the experiment understandable without exposing unnecessary management information.

The public report does not require:

```text
exact hypervisor address
router address
overlay VPN address
device identities
MAC addresses
machine IDs
filesystem UUIDs
credentials
SSH fingerprints
home-router configuration
```

The research VM is expendable.

The infrastructure controlling it is not.

Further hypervisor and management-plane hardening remains a separate infrastructure task and is not required to explain or reproduce the Copy Fail experiment.

---

## 29. Outstanding Verification

One procedural item should be checked before continuing:

```text
confirm that a clean rollback snapshot exists for the experimental clone
```

A pre-modification snapshot was planned, but its creation was not explicitly verified during this session.

This should be confirmed before PoC execution.

No assumption should be made that the snapshot exists until it has been checked in Proxmox.

---

## 30. Next Steps

The next session should continue from the current controlled state.

The immediate task is **not** to execute the PoC.

The next task is to expand the compact exploit source into readable steps and map each operation to the vulnerability mechanism.

Topics to examine include:

```text
AF_ALG socket family
SOCK_SEQPACKET usage
AEAD algorithm selection
authencesn(hmac(sha256),cbc(aes))
setsockopt parameters
ancillary control messages
pipe creation
splice()
scatterlist construction
in-place AEAD operation
four-byte overwrite primitive
page-cache interaction
embedded ELF payload
/usr/bin/su as the setuid target
```

Only after the PoC is understood should controlled reproduction begin.

The planned research sequence remains:

```text
understand PoC
        ↓
capture vulnerable-state evidence
        ↓
execute from labuser
        ↓
prove privilege escalation with UID 0 only
        ↓
study observable behavior
        ↓
design detection
        ↓
test benign workload
        ↓
apply custom compensating control
        ↓
prove exploit fails
        ↓
restore vendor mitigation
        ↓
test again
        ↓
boot patched kernel
        ↓
final comparison
```

No persistence, credential theft, lateral movement, reverse shell, or unnecessary post-exploitation activity is required.

Privilege escalation will be considered demonstrated once the ordinary laboratory user can independently show:

```text
uid=0(root)
```

through the vulnerability path.

---

## 31. Checkpoint Result

The session successfully transformed a patched Ubuntu reference installation into a controlled two-system Copy Fail research environment.

The patched reference was preserved.

A separate experimental clone was given its own host identity and network identity.

The firewall configuration was corrected so that dynamic experimental systems can be administered without creating a new per-address SSH rule for every clone.

Ubuntu's historical package archive was used to install the exact pre-fix candidate kernel while retaining the patched fallback kernel.

A missing virtual graphics module was diagnosed and restored with the matching historical package.

Canonical's independent `algif_aead` mitigation was identified, verified, and deliberately disabled only on the experimental clone.

The required AF_ALG modules were loaded.

A dedicated unprivileged account was created.

That account successfully accessed the kernel AEAD interface without receiving additional privileges.

Finally, the official Copy Fail PoC was downloaded, its apparent checksum mismatch was explained, and its high-level structure was inspected without execution.

The laboratory is now ready for the next phase:

```text
understand the 10-line PoC
before allowing the 10-line PoC to bully the Linux kernel
```
