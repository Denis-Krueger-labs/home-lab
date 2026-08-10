# Copy Fail Research Lab, MORI Detection and Selective Mitigation Development

**Date:** 10 August 2026  
**Hypervisor:** Proxmox VE 9.2  
**Firewall:** OPNsense `fw01`  
**Guest OS:** Ubuntu Server 24.04 LTS  
**Reference Kernel:** `6.8.0-137-generic`  
**Vulnerable Kernel:** `6.8.0-116-generic`  
**Research Target:** `copyfail-vuln`  
**Unprivileged Test User:** `labuser`  
**Detection System:** MORI Monitor  
**Compensating Control:** MORI Guard  
**Current Development Stage:** MORI Guard v2 / BPF LSM selective-control prototype  

## 1. Previous Checkpoint

The previous home-lab checkpoint established remote access into the isolated research network.

The final management path was:

```text
Physical workstation
        |
        | Tailscale
        v
Proxmox VE
        |
        | static route
        v
OPNsense
        |
        | firewall policy
        v
Isolated lab network
```

This allowed selected lab systems to be reached remotely without installing Tailscale directly on the research targets.

The important design decision was that OPNsense remained part of the traffic path.

Proxmox was not given an address directly inside the isolated research network.

This preserved the separation between:

```text
Remote transport      Tailscale
Routing               Proxmox
Network authorization OPNsense
Research target       Ubuntu VM
```

With remote management working, the next phase of the lab focused on the Linux kernel vulnerability CVE-2026-31431, commonly referred to as **Copy Fail**.

## 2. Goal of This Checkpoint

The purpose of this phase was not only to reproduce a public Linux privilege-escalation vulnerability.

The larger goal was to use the vulnerability as a complete defensive research exercise:

```text
vulnerability research
        |
        v
reference system
        |
        v
historically vulnerable system
        |
        v
controlled reproduction
        |
        v
observable system effect
        |
        v
custom detection
        |
        v
signature comparison
        |
        v
custom mitigation
        |
        v
compatibility testing
        |
        v
selective mitigation development
```

The experiment therefore included both offensive and defensive components.

The privilege escalation itself was intentionally limited to proving successful UID 0 execution.

No persistence, credential collection, reverse shell, lateral movement, or unrelated post-exploitation activity was performed.

## 3. Lab Evolution

Two related Ubuntu systems were used.

The existing Ubuntu research system served as the clean reference environment.

A full clone was then created for destructive vulnerability testing.

The two logical roles became:

```text
Reference system
        |
        | patched/current state
        |
        +--> comparison
        |
        v
Vulnerable clone
copyfail-vuln
        |
        | historical kernel
        |
        +--> reproduction
        +--> detection
        +--> mitigation
        +--> BPF development
```

The vulnerable clone was assigned the hostname:

```text
copyfail-vuln
```

The machine identity and SSH host keys were regenerated after cloning so that the two systems no longer shared host identity.

A dedicated unprivileged account was also created:

```text
labuser
UID 1001
```

The account deliberately does not belong to administrative groups such as:

```text
sudo
lxd
```

This ensured that a transition from:

```text
uid=1001(labuser)
```

to:

```text
uid=0(root)
```

could be treated as a meaningful privilege-escalation result.

## 4. Reference-System Validation

Before reconstructing a vulnerable environment, the reference Ubuntu system was inspected.

The reference machine was running:

```text
6.8.0-137-generic
```

The installed package version was:

```text
6.8.0-137.137
```

The system also contained an additional defensive configuration affecting the vulnerable interface.

The file:

```text
/etc/modprobe.d/disable-algif_aead.conf
```

contained:

```text
install algif_aead /bin/false
```

This prevented normal `modprobe` loading of:

```text
algif_aead
```

The relevant kernel configuration still contained:

```text
CONFIG_CRYPTO_USER_API_AEAD=m
```

and the module itself existed on disk.

The interface was therefore not removed from the kernel configuration.

Instead, module loading was deliberately blocked through the `modprobe` configuration.

This reference state established two independent defensive layers:

```text
patched kernel
        +
algif_aead load restriction
```

The vulnerable research system would later be configured differently so that the affected interface could be restored for controlled testing.

## 5. Reconstructing the Historical Vulnerable Kernel

The vulnerable test environment required a historical Ubuntu kernel.

The selected version was:

```text
6.8.0-116-generic
```

with package version:

```text
6.8.0-116.116
```

The historical packages remained available through the Canonical Ubuntu snapshot service at the snapshot used for the experiment.

The required kernel packages included:

```text
linux-image-6.8.0-116-generic
linux-modules-6.8.0-116-generic
linux-modules-extra-6.8.0-116-generic
```

Installing `linux-modules-extra` was important.

During the first historical-kernel boot, the console behaved incorrectly because expected graphics-related kernel modules were missing.

After the matching `linux-modules-extra` package was installed, the historical boot environment behaved normally.

The patched `6.8.0-137` kernel remained installed.

The system therefore contained both:

```text
6.8.0-137-generic
6.8.0-116-generic
```

The patched kernel remained the normal default.

The vulnerable kernel was selected with a one-shot GRUB entry when required.

This avoided permanently changing the normal boot target while still allowing controlled research on the historical version.

## 6. Restoring the Vulnerable Interface

The cloned system inherited the reference system's `algif_aead` module-loading restriction.

To reproduce the historical vulnerable state, the mitigation file was disabled reversibly rather than deleted.

The original configuration was retained but renamed so that it would no longer be interpreted by `modprobe`.

After doing so, a normal module-loading test confirmed that:

```text
af_alg
algif_aead
```

could be loaded.

A benign unprivileged AF_ALG AEAD test was also performed.

The test attempted an AEAD bind using:

```text
type:      aead
algorithm: gcm(aes)
```

The bind succeeded.

This proved that an unprivileged process could legitimately use the AEAD interface on the reconstructed vulnerable system.

That result later became important when evaluating mitigation compatibility.

## 7. Controlled Copy Fail Reproduction

The public Copy Fail proof of concept was obtained only inside the isolated research environment.

The local file used during the experiment had:

```text
Size:
731 bytes

SHA-256:
d401e7d1c00605749d6c617ace73ab20a762b72e41c2e1590331596e38219a61
```

The exploit source itself is not redistributed as part of the public evidence package.

Before execution, the system state was recorded.

The test user was:

```text
uid=1001(labuser)
gid=1001(labuser)
```

The privileged target `/usr/bin/su` was root-owned and SUID.

Its known-good SHA-256 value was:

```text
c74311fe5636b7d7f9a56239fa8adeeab12ba86fe7d41b91afa85bf9bbdae78b
```

The proof of concept was executed as `labuser`.

The result was a privileged shell.

Validation showed:

```text
uid=0(root)
```

and:

```text
whoami
root
```

This was treated as sufficient proof of successful privilege escalation.

The experiment did not continue into persistence or unrelated post-exploitation activity.

## 8. Modified Privileged-Executable View

After exploitation, the SHA-256 value observed through the normal mounted filesystem view of:

```text
/usr/bin/su
```

changed to:

```text
44900c631391f0d60eb6d271b8374a08dc1d9be76e403390d27a91ed5f179be9
```

After leaving the root shell, the user context returned to:

```text
uid=1001(labuser)
```

However, the modified hash remained visible through the mounted filesystem.

The important observation was therefore:

```text
before exploit
/usr/bin/su
c74311...

        |
        v

Copy Fail

        |
        v

after exploit
/usr/bin/su through mounted/VFS view
44900c...
```

This visible change later became the primary signal used by MORI Monitor.

## 9. Direct Backing-Filesystem Comparison

A direct comparison was performed between:

```text
normal mounted/VFS read
```

and:

```text
direct ext4 backing-filesystem read
```

The direct ext4 command was:

```bash
sudo debugfs -R 'cat /usr/bin/su' \
  /dev/mapper/ubuntu--vg-ubuntu--lv 2>/dev/null \
  | sha256sum
```

During the modified state, the normal mounted view returned:

```text
44900c631391f0d60eb6d271b8374a08dc1d9be76e403390d27a91ed5f179be9
```

The direct ext4 read returned:

```text
c74311fe5636b7d7f9a56239fa8adeeab12ba86fe7d41b91afa85bf9bbdae78b
```

The experiment therefore demonstrated:

```text
mounted/VFS-visible data != direct backing-filesystem read
```

No stronger kernel-internal conclusion was inferred from this comparison alone.

The important point for the lab was simply that ordinary file-integrity checks through the mounted filesystem could observe a changed privileged executable even though the direct backing read still produced the original content hash.

## 10. Cache-Drop Observation

During an earlier preliminary reproduction, cache-drop operations were tested.

Values:

```text
1
3
```

were written to the relevant cache-drop control.

Neither operation restored the original mounted-file hash during that experiment.

This result is retained only as an observation.

No causal explanation was assigned without additional kernel-level evidence.

## 11. Reboot Recovery

After the preserved reproduction run, the VM was rebooted again into:

```text
6.8.0-116-generic
```

The kernel was therefore still vulnerable.

After reboot, the normal mounted view of `/usr/bin/su` again returned:

```text
c74311fe5636b7d7f9a56239fa8adeeab12ba86fe7d41b91afa85bf9bbdae78b
```

The observed sequence was:

```text
clean vulnerable boot
        |
        v
Copy Fail
        |
        v
mounted-view hash changes
        |
        v
reboot into same vulnerable kernel
        |
        v
original mounted-view hash restored
```

The restoration did not depend on applying the patched kernel.

## 12. Privileged Execution Surface

The lab was also inspected for root-owned SUID executables.

Thirteen root-owned SUID files were identified.

Examples included:

```text
/usr/bin/chfn
/usr/bin/chsh
/usr/bin/gpasswd
/usr/bin/mount
/usr/bin/newgrp
/usr/bin/passwd
/usr/bin/su
/usr/bin/sudo
/usr/bin/umount
/usr/lib/openssh/ssh-keysign
```

The unprivileged `labuser` could read and execute twelve of the identified targets.

`/usr/bin/su` remained the only target actually demonstrated during the Copy Fail reproduction.

The remaining files are therefore treated as:

```text
candidate privileged targets
```

rather than:

```text
confirmed Copy Fail targets
```

This distinction is important because the lab did not individually reproduce exploitation against every SUID executable.

## 13. Detection Design

The successful reproduction created an interesting defensive problem.

A normal file-write event was not necessarily the most useful observable because the tested effect did not behave like an ordinary persistent write to `/usr/bin/su`.

However, a normal read of the privileged executable through the mounted filesystem returned the modified content.

This suggested a simple defensive experiment:

```text
protected privileged executable
        |
        v
known-good SHA-256
        |
        v
periodic mounted-file read
        |
        v
compare current hash
```

This became **MORI Monitor**.

## 14. MORI Monitor

MORI Monitor is a small Python integrity watcher.

It maintains a known-good SHA-256 baseline for the protected SUID executables.

The service periodically reads each protected binary and compares its current hash with the baseline.

The interval used during the experiment is:

```text
0.25 seconds
```

The normal state is represented as:

```text
 /\_/\
( •.• )   MORI: privileged binaries look normal.
 > ^ <
```

The monitor runs as a hardened systemd service:

```text
mori-integrity.service
```

The baseline is stored separately from the monitored executables.

The design does not rely on:

```text
proof-of-concept filename
proof-of-concept SHA-256
process name
exploit source code
```

Instead, the detector observes the resulting privileged-file state.

## 15. Successful MORI Detection

MORI Monitor was running during another controlled Copy Fail reproduction.

The same privilege escalation again produced a root shell.

At the same time, MORI observed that:

```text
/usr/bin/su
```

no longer matched the known-good baseline.

The alert appeared as:

```text
 /\_/\
( Ò.Ó )   MORI: INTEGRITY VIOLATION.
 > ^ <
```

The recorded values were:

```text
Expected:
c74311fe5636b7d7f9a56239fa8adeeab12ba86fe7d41b91afa85bf9bbdae78b

Observed:
44900c631391f0d60eb6d271b8374a08dc1d9be76e403390d27a91ed5f179be9
```

This established that MORI could detect the privileged-file state produced by the tested exploitation path.

MORI Monitor remained a detection mechanism only.

It did not prevent the privilege escalation.

## 16. Exact-Sample YARA Comparison

A small YARA experiment was then performed to compare:

```text
exact sample identification
```

with:

```text
outcome-based integrity monitoring
```

An exact-hash YARA rule was created for the laboratory copy of the PoC.

The known sample produced:

```text
MATCH
```

A harmless comparison file was then produced by appending a single trailing newline.

The file size changed from:

```text
731 bytes
```

to:

```text
732 bytes
```

The new SHA-256 value became:

```text
a567d09b15f6e4440e70c9f2aa8edec8ed59f53301952df05c719aa3911687f9
```

The exact-hash YARA rule no longer matched.

The modified file was not executed.

This experiment does not demonstrate that YARA itself is ineffective.

YARA supports generalized strings, byte patterns, structures and many other matching strategies.

The result only demonstrated that:

```text
exact-hash identification
```

is inherently tied to one precise byte representation.

MORI's integrity detection instead observes the resulting privileged-file state.

## 17. MORI Guard v1

After detection had been demonstrated, the next goal was to prevent the tested exploitation chain while deliberately retaining the vulnerable kernel.

A custom compensating control called:

```text
MORI Guard
```

was created.

The initial design used a `modprobe` install override:

```text
/etc/modprobe.d/mori-copyfail-guard.conf
```

containing:

```text
install algif_aead /usr/local/sbin/mori-block-algif-aead
```

Requests to load the affected module were redirected through a custom blocker.

The blocker logged the denial and returned a failure status.

The user-visible message was:

```text
            ⁺‧₊˚ ཐི⋆♱⋆ཋྀ ˚₊‧⁺

 /\_/\
( Ò.Ó )   MORI GUARD
 > ^ <

One of my trusted moths has informed me
that you are touching my binaries.

I do not share my binaries.
They are mine.

Begone.
You are scaring the moths.
```

The message itself was cosmetic.

The security control was the failed module-load request.

## 18. MORI Guard v1 Retest

The system remained on:

```text
6.8.0-116-generic
```

The same unprivileged account and same proof of concept were used.

With MORI Guard active, `algif_aead` could no longer become available through the tested module-loading path.

The proof of concept terminated with:

```text
FileNotFoundError
Errno 2
No such file or directory
```

After the attempt:

```text
labuser remained UID 1001
```

and:

```text
/usr/bin/su
```

still had:

```text
c74311fe5636b7d7f9a56239fa8adeeab12ba86fe7d41b91afa85bf9bbdae78b
```

MORI Guard logged the denied module-load request.

MORI Monitor produced no integrity alert because the protected executable did not change.

The result was:

```text
Copy Fail attempt
        |
        v
algif_aead requested
        |
        v
MORI Guard blocks availability
        |
        v
PoC terminates
        |
        v
no UID 0
        |
        v
/usr/bin/su unchanged
```

The compensating control therefore interrupted the tested exploit chain.

## 19. Compatibility Test

The exploit-blocking result alone was not considered sufficient.

The benign AF_ALG AEAD test used earlier in the lab was repeated while MORI Guard v1 was active.

The benign operation attempted:

```text
AF_ALG
type: aead
algorithm: gcm(aes)
```

It failed with:

```text
FileNotFoundError
errno=2
```

This produced an important negative result.

MORI Guard v1 could not distinguish:

```text
malicious use of algif_aead
```

from:

```text
legitimate use of algif_aead
```

Its effective policy was:

```text
AEAD required by exploit  -> DENY
benign AEAD               -> DENY
```

The control worked as an exploit interruption mechanism but was too broad to be considered selective.

## 20. Why MORI Guard v2 Exists

The compatibility failure became the design requirement for MORI Guard v2.

The desired behavior is:

```text
benign AEAD
        |
        v
      ALLOW


ordinary SUID access
        |
        v
      ALLOW


Copy Fail-relevant behavior
        |
        v
      DENY
```

The goal is not to identify malicious intent.

A kernel policy cannot determine whether a user is "evil".

Instead, MORI v2 should identify a narrow combination of behaviors associated with the tested exploitation chain.

The development process therefore moved from:

```text
interface-level blocking
```

toward:

```text
behavioral correlation
```

## 21. BPF LSM Capability Investigation

eBPF and Linux Security Module support were investigated on the same vulnerable kernel.

The initial capability check returned:

```text
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_BPF_LSM=y
CONFIG_SECURITY=y
CONFIG_DEBUG_INFO_BTF=y
```

Kernel BTF was also available at:

```text
/sys/kernel/btf/vmlinux
```

However, the initially active LSM stack was:

```text
lockdown,capability,landlock,yama,apparmor
```

`bpf` was not active.

The configured built-in LSM list was:

```text
CONFIG_LSM="landlock,lockdown,yama,integrity,apparmor"
```

This meant:

```text
BPF LSM compiled into kernel  Yes
BPF LSM active at boot        No
```

## 22. Matching Historical BPF Tools

The host already contained `bpftool`, but the Ubuntu wrapper initially reported:

```text
WARNING: bpftool not found for kernel 6.8.0-116
```

The currently installed tools belonged to:

```text
6.8.0-137
```

rather than:

```text
6.8.0-116
```

The same Ubuntu snapshot used for the vulnerable kernel still contained the exact historical tools packages:

```text
linux-tools-6.8.0-116
linux-tools-6.8.0-116-generic
```

version:

```text
6.8.0-116.116
```

These were installed without upgrading the vulnerable kernel.

After installation:

```text
bpftool v7.4.0
libbpf v1.4
```

became available for the running historical kernel.

A feature probe confirmed:

```text
eBPF program_type lsm is available
```

This established that the historical kernel could load BPF LSM programs.

## 23. Enabling BPF LSM

The existing GRUB configuration contained:

```text
GRUB_DEFAULT=0
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX=""
```

The configuration was backed up before modification.

The active LSM list was extended by changing:

```text
GRUB_CMDLINE_LINUX=""
```

to:

```text
GRUB_CMDLINE_LINUX="lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
```

The existing LSMs were intentionally preserved.

The goal was not to replace AppArmor, Yama, Landlock or the other security layers.

The new configuration only appended:

```text
bpf
```

`update-grub` generated the expected vulnerable-kernel boot entry:

```text
linux /vmlinuz-6.8.0-116-generic ... ro lsm=landlock,lockdown,yama,integrity,apparmor,bpf
```

Because `6.8.0-137` remained the default kernel, a one-shot GRUB boot was again used for the historical `6.8.0-116` kernel.

After reboot:

```bash
uname -r
```

returned:

```text
6.8.0-116-generic
```

The kernel command line contained:

```text
lsm=landlock,lockdown,yama,integrity,apparmor,bpf
```

The active stack became:

```text
lockdown,capability,landlock,yama,apparmor,bpf
```

This confirmed that the BPF LSM was now active on the vulnerable kernel.

## 24. BPF Development Environment

A small build environment was then installed.

The relevant tools became:

```text
clang 18.1.3
gcc 13.3.0
GNU Make 4.3
libbpf 1.3.0
bpftool 7.4.0
```

Clang confirmed support for:

```text
Target: bpf
```

Kernel type information was generated directly from BTF:

```bash
bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
```

The generated file was approximately:

```text
3.1 MiB
```

with SHA-256:

```text
9afb58909604112dc7a303acef1e12ccd1edd6e3a066bb81fef69278a267af9a
```

This allowed the BPF prototype to use kernel type information without manually recreating internal structure definitions.

## 25. MORI v2.0 Observer

The first BPF program was intentionally harmless.

Rather than immediately enforcing policy, MORI v2.0 attached to:

```text
lsm/file_permission
```

and observed access to:

```text
root-owned SUID files
```

The program always returned the existing LSM result.

Its logical behavior was:

```text
file_permission()
        |
        v
root-owned SUID?
        |
        +-- no --> ignore
        |
        `-- yes
             |
             v
            log
             |
             v
       preserve result
```

The BPF object compiled successfully as:

```text
ELF 64-bit LSB relocatable, eBPF
```

The object contained:

```text
lsm/file_permission
.BTF
.BTF.ext
```

A libbpf skeleton was generated with:

```bash
bpftool gen skeleton mori_observer.bpf.o > mori_observer.skel.h
```

A small userspace loader then performed:

```text
open
load
attach
wait
destroy
```

The observer successfully attached to the running kernel.

## 26. MORI v2.1 Filtering

The initial observer produced too much output.

The filter was therefore narrowed to:

```text
non-root caller
        +
MAY_READ
        +
root-owned SUID target
```

The resulting trace format became:

```text
MORI v2.1 READ-SUID pid=<PID> uid=<UID> mask=4
```

This was still observation-only.

No file access was blocked.

A normal read such as:

```bash
cat /usr/bin/su > /dev/null
```

continued to succeed.

The intent was to reduce background noise before adding stronger behavioral correlation.

## 27. MORI Attacks MORI

The filtered observer immediately produced an unexpected result.

The trace output began repeatedly logging:

```text
MORI v2.1 READ-SUID pid=702 uid=63487 mask=4
```

The process was:

```text
python3
PID 702
UID 63487
```

The output occurred at a very high rate.

At first glance, this appeared to be a non-root Python process repeatedly reading privileged SUID executables.

The process was therefore investigated.

## 28. Identifying PID 702

The process was inspected with:

```bash
ps -o pid,user,uid,comm,args -p 702
```

Result:

```text
PID  USER            UID    COMMAND
702  mori-integrity  63487  python3
```

Its command line was:

```text
/usr/bin/python3 -u /usr/local/lib/copyfail-detector/mori_integrity_watch.py
```

The cgroup was:

```text
/system.slice/mori-integrity.service
```

The executable resolved to:

```text
/usr/bin/python3
```

The systemd service was:

```text
mori-integrity.service
```

The dynamic account was also confirmed:

```text
mori-integrity:x:63487:63487:Dynamic User:/:/usr/sbin/nologin
```

The supposed suspicious process was therefore the existing MORI integrity monitor.

MORI v2 had detected MORI v1.

## 29. Why the False Positive Occurred

MORI Monitor checks twelve privileged executables every:

```text
0.25 seconds
```

To calculate their SHA-256 values, the service must read those files.

Its legitimate behavior therefore matches the v2.1 rule perfectly:

```text
non-root process
        +
READ
        +
root-owned SUID target
```

The BPF program was not malfunctioning.

The rule was behaving exactly as written.

The mistake was the assumption that this combination alone represented sufficiently suspicious behavior.

The incident can be summarized as:

```text
MORI Monitor
        |
        | hashes protected binaries
        v
READ root-owned SUID
        |
        v
MORI v2.1
        |
        v
"suspicious!"
        |
        v
process = MORI Monitor
```

Or, less formally:

```text
 /\_/\
( Ò.Ó )   MORI: WHO IS TOUCHING MY BINARIES?
 > ^ <

 /\_/\
( •.• )   ...oh. me.
 > ^ <
```

## 30. False-Positive Evidence

Three screenshots were retained for this development result.

### 30.1 Process Identification

```text
00-mori-v2-identifies-mori-monitor-process.png
```

The screenshot records:

```text
PID
UID
process name
command line
cgroup
systemd service
```

and proves that PID 702 belongs to MORI Monitor.

### 30.2 False-Positive Trace

```text
01-mori-v2-false-positive-mori-monitor.png
```

The screenshot shows repeated events:

```text
MORI v2.1 READ-SUID pid=702 uid=63487 mask=4
```

This is the primary false-positive evidence.

### 30.3 Service Context

```text
02-mori-monitor-service-context.png
```

The service journal confirms that MORI Monitor is intentionally:

```text
Watching 12 privileged files
Check interval: 0.25 seconds
```

This explains why the BPF observer generated so many events.

## 31. Why PID or UID Whitelisting Is Not Appropriate

The simplest possible workaround would be to ignore:

```text
PID 702
```

or:

```text
UID 63487
```

Neither is desirable.

The PID is transient.

A service restart would produce a different process identifier.

The account uses a systemd dynamic user.

Its numerical UID should therefore not be treated as a permanent identity.

Ignoring:

```text
python3
```

would be even worse because it would exempt every Python process.

The observed values are useful for investigation but are poor long-term security identifiers.

## 32. Planned MORI Self-Protection

The current design idea is to identify MORI Monitor through its service boundary rather than a transient process identifier.

The systemd service reports:

```text
ControlGroup=/system.slice/mori-integrity.service
```

The corresponding cgroup path is:

```text
/sys/fs/cgroup/system.slice/mori-integrity.service
```

Its current cgroup inode was:

```text
2482
```

The process itself reports:

```text
0::/system.slice/mori-integrity.service
```

The planned direction is therefore:

```text
MORI v2 userspace loader
        |
        v
validate expected MORI Monitor
        |
        v
resolve mori-integrity.service
        |
        v
obtain trusted cgroup identity
        |
        v
populate BPF trusted-service map
```

The BPF program can then ignore only the specific expected integrity-read behavior generated by that trusted service.

The exemption should not make MORI Monitor globally invisible to every future MORI policy.

The desired scope is:

```text
trusted MORI service
        +
expected integrity reads
        |
        v
ignore this specific signal
```

rather than:

```text
trusted MORI service
        |
        v
ignore everything forever
```

## 33. Using MORI Monitor's Hash as a Trust Prerequisite

A second idea is to incorporate the known-good SHA-256 value of the MORI Monitor implementation into the userspace trust decision.

The hash would not directly become the kernel policy.

Instead, the design would be:

```text
MORI v2 loader starts
        |
        v
verify known-good MORI Monitor implementation
        |
     +--+--+
     |     |
  match  mismatch
     |     |
     v     v
resolve   refuse
trusted   exemption
service
     |
     v
resolve service cgroup
     |
     v
install narrow trusted-cgroup entry
```

This combines:

```text
static trust
known-good implementation

        +

runtime identity
systemd service cgroup
```

The implementation has not yet been completed.

It remains the next MORI v2 development step.

## 34. Planned Behavioral Correlation

The larger purpose of MORI v2 is not merely to suppress the self-generated false positive.

The eventual policy needs more context than:

```text
read root-owned SUID file
```

The current behavioral hypothesis combines multiple signals:

```text
AF_ALG AEAD activity
        +
splice-related execution context
        +
read of root-owned SUID target
```

Each individual operation may be legitimate.

The suspicious signal is the combination.

The intended progression is:

```text
MORI v2.0
observer
LOG ONLY

        |
        v

MORI v2.1
filtered observer
LOG ONLY

        |
        v

MORI v2.2
behavior correlation
LOG ONLY

        |
        v

MORI v2 shadow policy
WOULD DENY

        |
        v

MORI v2 enforcement
DENY
```

Enforcement will only be introduced after the observer has demonstrated that the chosen behavior is sufficiently selective.

## 35. Intended MORI v2 Test Matrix

The final selective-control test should include at least:

| Test | Expected Result |
|---|---|
| Benign AF_ALG `gcm(aes)` bind | Allow |
| Second benign AEAD operation | Allow |
| Normal read of `/usr/bin/su` | Allow |
| Normal execution of `/usr/bin/su` | Allow |
| Normal read of another protected SUID executable | Allow |
| Ordinary `splice()` involving non-privileged data | Allow |
| MORI Monitor integrity scan | Allow / no suspicious correlation |
| Copy Fail proof of concept | Deny |
| `labuser` after blocked attempt | UID 1001 |
| `/usr/bin/su` after blocked attempt | Known-good hash |
| MORI Monitor after blocked attempt | No integrity violation |

The policy should also avoid relying on:

```text
copy_fail_exp.py
known PoC hash
PID
dynamic UID
Python process name
/usr/bin/su alone
```

## 36. Evidence Packaging Cleanup

The public Copy Fail repository was also reviewed before continuing with MORI v2.

Several documentation issues were corrected.

### 36.1 Baseline Manifest Encoding

The baseline public SHA-256 manifest contained a UTF-8 BOM.

This caused the first entry to be skipped by some verification workflows.

The manifest was rewritten as plain ASCII.

Verification then produced:

```text
20 OK / 0 FAIL
```

### 36.2 Reproduction README

The reproduction README contained escaped Markdown headings and HTML-space artifacts.

Examples included:

```text
\#
\##
&#x20;
```

These were removed.

### 36.3 Proof-of-Concept Screenshot

A reproduction screenshot contained the complete proof-of-concept source.

This contradicted the repository's stated handling policy.

The screenshot:

```text
04-copy-fail-poc-source.png
```

was removed from the public evidence package.

The numbering remains intentionally absent so that the original experimental sequence is still understandable.

### 36.4 Reproduction Methodology

The exact backing-filesystem command was added to the public documentation:

```bash
sudo debugfs -R 'cat /usr/bin/su' \
  /dev/mapper/ubuntu--vg-ubuntu--lv 2>/dev/null \
  | sha256sum
```

The README also now documents that the preliminary experiment and preserved reproduction run were separated by a reboot into the same vulnerable kernel.

### 36.5 Public Manifest Verification

The final reproduction package verified:

```text
12 OK / 0 FAIL
```

The MORI Guard v1 evidence package verified:

```text
19 OK / 0 FAIL
```

The main MORI detection package verified:

```text
22 OK / 0 FAIL
```

The cleanup was committed as:

```text
Polish evidence packaging and methodology
```

The public repository therefore has a clear historical boundary before MORI v2 development.

## 37. Snapshot Strategy

A Proxmox snapshot was preserved before vendor-patch testing.

The relevant snapshot is:

```text
pre-vendor-patch-mori-guard
```

It represents a state containing:

```text
vulnerable kernel 6.8.0-116
MORI Monitor validated
MORI Guard v1 validated
vendor patch not yet applied
```

This allows later testing to return to a known vulnerable state without rebuilding the environment from scratch.

The vulnerable kernel remains deliberately installed while the custom controls are being developed.

## 38. Security Boundaries

Several restrictions remain deliberate throughout the experiment.

### 38.1 Isolated Environment

All vulnerability reproduction occurs inside the private lab.

The test system is not an external or third-party target.

### 38.2 Unprivileged Starting User

The exploit is executed from:

```text
labuser
UID 1001
```

without administrative group membership.

### 38.3 Minimal Privilege-Escalation Validation

Successful exploitation is demonstrated using:

```text
id
whoami
```

No persistence is added.

### 38.4 No Credential Collection

The experiment does not attempt to collect:

```text
passwords
SSH keys
tokens
browser data
```

### 38.5 Proof-of-Concept Handling

The exploit source is used in the private lab but is not intentionally redistributed through the public evidence package.

### 38.6 Vendor Patch Remains Preferred

MORI Guard is treated as a compensating control.

It does not replace fixing the vulnerable kernel.

The final lab phase will still apply the vendor remediation and repeat the tests.

## 39. Debugging Method

The same general troubleshooting principle used in the previous networking checkpoint was reused here:

```text
observe first
change one thing
measure again
```

The vulnerability work progressed through:

```text
1. Validate patched reference state
2. Identify vendor-side algif_aead restriction
3. Reconstruct historical kernel
4. Restore vulnerable interface
5. Validate benign AF_ALG AEAD use
6. Establish unprivileged test account
7. Record known-good SUID target
8. Reproduce Copy Fail
9. Validate UID 0
10. Compare mounted and backing-file views
11. Reboot into same vulnerable kernel
12. Confirm restored hash
13. Inventory privileged targets
14. Build integrity monitor
15. Reproduce exploit with monitor active
16. Confirm MORI detection
17. Compare with exact-hash YARA
18. Build MORI Guard v1
19. Confirm exploit interruption
20. Test benign AEAD compatibility
21. Discover overly broad mitigation
22. Investigate BPF LSM support
23. Install matching historical kernel tools
24. Enable BPF LSM
25. Build first observation-only program
26. Filter to non-root SUID reads
27. Observe unexpected PID 702 noise
28. Resolve PID 702 to MORI Monitor
29. Classify result as false positive
30. Design narrow trusted-service exclusion
```

The important lesson was again to avoid changing several variables at once.

The MORI v2 false positive was useful precisely because enforcement had not yet been enabled.

The program could be inspected and refined without accidentally blocking normal workloads.

## 40. Current Status

| Component | Status |
|---|---|
| Remote workstation to Proxmox through Tailscale | Working |
| OPNsense isolated lab routing | Working |
| Vulnerable clone `copyfail-vuln` | Working |
| Historical kernel `6.8.0-116-generic` | Working |
| Unprivileged `labuser` | Configured |
| `algif_aead` vulnerable-interface availability | Validated |
| Copy Fail privilege escalation | Reproduced |
| UID 0 result | Confirmed |
| Mounted `/usr/bin/su` hash change | Confirmed |
| Direct backing ext4 comparison | Confirmed |
| Same-kernel reboot recovery | Confirmed |
| MORI Monitor | Working |
| Real Copy Fail integrity alert | Confirmed |
| Exact-hash YARA comparison | Completed |
| MORI Guard v1 | Working |
| MORI Guard v1 exploit block | Confirmed |
| MORI Guard v1 benign AEAD compatibility | Failed |
| MORI Guard v1 selectivity | Insufficient |
| BPF LSM compiled into vulnerable kernel | Yes |
| BPF LSM active | Yes |
| Kernel BTF | Available |
| Matching `bpftool` | Installed |
| Clang BPF target | Working |
| libbpf development environment | Working |
| `vmlinux.h` generation | Working |
| MORI v2.0 LSM observer | Working |
| MORI v2.1 SUID-read filtering | Working |
| MORI v2.1 false positive | Identified |
| False positive source | MORI Monitor itself |
| Trusted-cgroup exemption | Planned |
| AEAD correlation | Planned |
| Splice correlation | Planned |
| Shadow deny policy | Planned |
| MORI v2 enforcement | Planned |
| Vendor patch validation | Pending |
| Final patched-system retest | Pending |

## 41. Current Research Structure

The current logical structure is:

```text
                        Proxmox VE
                            |
                            v
                       OPNsense fw01
                            |
                            v
                     Isolated lab network
                            |
             +--------------+--------------+
             |                             |
             v                             v
       Reference VM                  copyfail-vuln
       patched/current               6.8.0-116
                                           |
                                           |
                     +---------------------+--------------------+
                     |                     |                    |
                     v                     v                    v
               Copy Fail PoC          MORI Monitor         MORI Guard
                                         v1                 v1 / v2
                     |                     |                    |
                     |                     |                    |
                     +-----------> /usr/bin/su <---------------+
                                           |
                                           v
                                 privileged target state
```

The defensive development path is:

```text
Copy Fail
   |
   v
MORI Monitor
detect outcome
   |
   v
MORI Guard v1
block entire interface
   |
   v
benign compatibility failure
   |
   v
MORI Guard v2
behavior-aware BPF LSM
```

## 42. Lessons Learned

The largest lesson from this checkpoint is that a control can be technically successful and still be the wrong control.

MORI Guard v1 successfully prevented the tested exploit.

It also prevented legitimate AEAD use.

The negative compatibility result was therefore as valuable as the successful exploit-blocking result.

Other useful lessons were:

* historical kernel research may require matching historical kernel tools,
* retaining the patched kernel alongside the vulnerable kernel makes comparison easier,
* one-shot GRUB boots are useful when the default system should remain patched,
* `linux-modules-extra` can be essential when reproducing an older Ubuntu kernel environment,
* validating a benign workload before mitigation provides a useful compatibility baseline,
* proving UID 0 is enough for a controlled privilege-escalation experiment,
* direct backing-filesystem reads can provide a useful comparison against the mounted filesystem view,
* observations should not be turned into stronger kernel explanations without evidence,
* integrity monitoring can detect security-relevant state even when normal write-oriented monitoring is not the chosen signal,
* exact-hash signatures identify exact artifacts rather than generalized behavior,
* compensating controls should be tested against legitimate workloads,
* BPF LSM should be introduced incrementally because it can become an enforcement mechanism,
* observation-only prototypes are safer than beginning with `DENY`,
* a technically correct rule can still generate false positives,
* security software itself may generate behavior that resembles the activity being monitored,
* transient PIDs are poor whitelist identities,
* dynamic UIDs are poor whitelist identities,
* process names are usually too broad for security exceptions,
* service cgroups provide a more meaningful runtime identity than a PID,
* trusted-tool exemptions should be narrow rather than global,
* detection rules improve when multiple independent signals are correlated,
* and negative experimental results should be preserved rather than hidden.

The most entertaining lesson was:

```text
security monitoring can monitor security monitoring
```

and apparently become suspicious of itself.

## 43. Next Steps

The lab is currently paused at the MORI v2 false-positive investigation.

### 43.1 MORI Self-Protection

The next step is to prevent expected MORI Monitor integrity reads from generating the preliminary SUID-read signal.

The planned approach is:

```text
known-good MORI Monitor validation
        +
systemd service identity
        +
trusted cgroup map
```

rather than:

```text
hard-coded PID
hard-coded dynamic UID
process-name whitelist
```

### 43.2 AF_ALG AEAD Observation

After the self-generated noise is controlled, MORI v2 should observe AF_ALG AEAD activity.

This stage remains logging-only.

### 43.3 Splice Correlation

The next signal will investigate the relationship between:

```text
AEAD context
splice activity
privileged target read
```

The resulting behavior should first be recorded rather than blocked.

### 43.4 Shadow Policy

Once the behavioral combination is validated, MORI can produce:

```text
WOULD DENY
```

events while still returning an allow result.

This allows the policy to be tested against benign workloads without risking immediate service disruption.

### 43.5 Enforcement

Only after the shadow policy is sufficiently selective should MORI Guard v2 return an actual denial result.

The primary test will again use the same Copy Fail proof of concept and vulnerable kernel.

### 43.6 Compatibility Matrix

The final v2 validation should confirm:

```text
benign AEAD          works
normal SUID access   works
MORI Monitor         works
Copy Fail            fails
labuser remains      UID 1001
/usr/bin/su          unchanged
```

### 43.7 Vendor Patch

After custom-control testing is complete, the vendor remediation will be applied.

The patched state will then be tested using the same methodology.

### 43.8 Final Retest

The final phase should compare:

```text
vulnerable + no mitigation
vulnerable + MORI Guard v1
vulnerable + MORI Guard v2
vendor-patched system
```

This will separate:

```text
detection
compensating control
selective compensating control
actual remediation
```

## 44. Checkpoint Result

Since the previous remote-access checkpoint, the home lab has evolved from a remotely manageable isolated network into a complete Linux vulnerability-research environment.

CVE-2026-31431 was reproduced using an intentionally unprivileged account on a historically vulnerable Ubuntu kernel.

The experiment confirmed local privilege escalation, recorded the resulting change visible through the mounted privileged executable, compared that state with the backing ext4 filesystem, and demonstrated recovery after rebooting into the same vulnerable kernel.

MORI Monitor was then created to detect the privileged-file integrity change.

The detector successfully identified a real Copy Fail reproduction without relying on the exploit filename or exact exploit hash.

A YARA exact-sample comparison demonstrated the difference between exact artifact identification and security-relevant outcome monitoring.

MORI Guard v1 successfully interrupted the tested exploit by blocking availability of the affected AEAD interface.

Compatibility testing then showed that the same control also broke benign AF_ALG AEAD use.

Rather than treating that result as a completed mitigation, the failure became the design requirement for MORI Guard v2.

The vulnerable kernel was shown to support BPF LSM, matching historical kernel tools were installed, BPF was added to the active LSM stack, and an observation-only BPF prototype was successfully compiled and attached.

The first filtered observer then produced an unexpected false positive by detecting the existing MORI Monitor service while it legitimately hashed the protected SUID executables.

That result established that:

```text
non-root + SUID read
```

is not sufficient context for selective mitigation.

MORI v2 development will therefore continue using narrower runtime identity and multi-signal behavioral correlation.

The current state of the lab is:

```text
Copy Fail               reproduced
MORI detection          working
MORI Guard v1           working but too broad
BPF LSM                 working
MORI v2 observation     working
MORI v2 selectivity     under development
vendor remediation      not yet applied
```

The lab is now ready for the next iteration:

```text
teach MORI to distinguish
"someone is using the system"
from
"someone is trying to eat the kernel"
```
