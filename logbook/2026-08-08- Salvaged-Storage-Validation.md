# Salvaged Storage Validation  Seagate FireCuda 2 TB

**Date:** 7 August 2026  
**System:** Windows 11 laptop  
**Device:** Seagate FireCuda `ST2000LX001-1RG174`  
**Device type:** 2.5-inch SATA SSHD  
**Nominal capacity:** 2 TB  
**Connection:** USB-to-SATA bridge  
**Goal:** Determine whether a salvaged Seagate FireCuda drive is functional, inspect its existing layout, verify whether data is present, and establish whether the disk is suitable for reuse as non-critical home-lab storage.

---

## 1. Starting Point

Several older storage devices were recovered for possible reuse in the home lab.

The collection included both 2.5-inch and 3.5-inch SATA drives. An existing USB-to-SATA adapter was initially used to test the disks from a Windows laptop.

The first tests with 3.5-inch drives produced an unusual result:

```text
VirtualDisk USB Device     USB     0     OK
```

Windows detected the USB bridge itself, but no usable storage capacity appeared behind it.

Inspection of the drives showed that the 3.5-inch disks required both 5 V and 12 V SATA power. The small USB-to-SATA adapter could communicate over USB, but could not provide the required 12 V supply for a 3.5-inch HDD.

The 2.5-inch FireCuda was therefore selected for the next test because it can normally be powered directly through a suitable USB-to-SATA adapter.

The immediate questions were:

1. Does the drive spin and enumerate correctly?
2. Does Windows detect its full capacity?
3. Is the existing partition table valid?
4. Is there any existing data worth preserving?
5. Can SMART information be retrieved through the current USB bridge?
6. Is the drive healthy enough to consider for lab use?

No formatting, initialization, repair, or partition modification was performed during the initial inspection.

---

## 2. Physical Drive Detection

The FireCuda was connected to the laptop using the existing USB-to-SATA adapter.

Windows successfully detected the actual disk instead of only the USB bridge.

The following command was used:

```powershell
Get-CimInstance Win32_DiskDrive |
    Select-Object Model, InterfaceType, Size, Status
```

The relevant result was:

```text
Model                          InterfaceType          Size Status
-----                          -------------          ---- ------
ST2000LX 001-1RG174 USB Device USB           2000396321280 OK
NVMe PVC10 SK hynix 1024GB     SCSI          1024203640320 OK
```

The salvaged drive was therefore identified as:

```text
ST2000LX001-1RG174
```

with approximately:

```text
2,000,396,321,280 bytes
```

of detected capacity.

This confirmed several basic properties immediately:

* the drive receives sufficient power through the current adapter,
* the drive spins and responds to commands,
* the USB-to-SATA bridge can communicate with the device,
* and Windows sees approximately the expected 2 TB capacity.

The generic `Status: OK` value was treated only as confirmation that Windows could communicate with the disk. It was not considered proof of physical disk health.

---

## 3. Windows Disk Detection

The next command was:

```powershell
Get-Disk
```

The FireCuda appeared as disk 1 and was reported as healthy and online.

More detailed information was collected with:

```powershell
Get-Disk -Number 1 |
    Format-List Number,FriendlyName,SerialNumber,PartitionStyle,Size,HealthStatus,OperationalStatus
```

Result:

```text
Number            : 1
FriendlyName      : ST2000LX 001-1RG174
SerialNumber      : 123400000022EAB
PartitionStyle    : GPT
Size              : 2000398932480
HealthStatus      : Healthy
OperationalStatus : Online
```

The disk therefore contains a valid GPT partition table and is accessible to Windows.

The reported serial number may originate from the USB-to-SATA bridge rather than directly from the drive and should not yet be treated as authoritative hardware identification.

---

## 4. Existing Partition Layout

The partition table was inspected without modifying it:

```powershell
Get-Partition -DiskNumber 1 |
    Format-Table PartitionNumber,DriveLetter,Type,Size
```

Result:

```text
PartitionNumber DriveLetter Type              Size
--------------- ----------- ----              ----
1                           Reserved      16759808
2              E            Basic    2000381018112
```

The layout is therefore approximately:

```text
Disk 1  GPT  ~2 TB

├── Partition 1
│   ├── Type: Microsoft Reserved
│   └── Size: ~16 MB
│
└── Partition 2
    ├── Type: Basic data
    ├── Drive letter: E:
    └── Size: ~2 TB
```

No unusual or fragmented partition layout was present.

The 16 MB reserved partition is consistent with a Windows-created GPT disk layout.

---

## 5. Filesystem Inspection

The main data volume was inspected with:

```powershell
Get-Volume -DriveLetter E |
    Format-List DriveLetter,FileSystemLabel,FileSystem,Size,SizeRemaining,HealthStatus
```

Result:

```text
DriveLetter     : E
FileSystemLabel : DATA
FileSystem      : NTFS
Size            : 2000381014016
SizeRemaining   : 2000211120128
HealthStatus    : Healthy
```

The volume is therefore:

```text
Label:       DATA
Filesystem:  NTFS
Capacity:    ~2 TB
Free space:  ~2 TB
```

Only a very small amount of space is currently occupied.

An initial directory listing returned no visible user files:

```powershell
Get-ChildItem E:\
```

No entries were shown.

A second inspection included hidden and system files:

```powershell
Get-ChildItem E:\ -Force
```

Result:

```text
    Verzeichnis: E:\

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d--hs-        07.08.2026     18:09                System Volume Information
```

The only visible filesystem object was:

```text
System Volume Information
```

This directory is automatically created and maintained by Windows.

No existing user data was discovered.

The disk therefore appears to have already been emptied or formatted before acquisition.

---

## 6. SMART Tool Installation

Windows' own `Healthy` status does not provide enough information to decide whether an older mechanical drive is safe to reuse.

SMART data was therefore chosen as the next validation step.

The first attempt failed because `smartctl` was not installed:

```powershell
smartctl --scan
```

Result:

```text
smartctl : Die Benennung "smartctl" wurde nicht als Name eines Cmdlet,
einer Funktion, einer Skriptdatei oder eines ausführbaren Programms erkannt.
```

The package was located through `winget`:

```powershell
winget search smartmontools
```

Result:

```text
smartmontools smartmontools.smartmontools 7.5
```

After installing smartmontools and reopening PowerShell, the installation was confirmed:

```powershell
smartctl --version
```

Result:

```text
smartctl 7.5 2025-04-30 r5714 [x86_64-w64-mingw32-w11-b26200]
```

The SMART tooling was now available.

---

## 7. Device Discovery Through smartctl

The available storage devices were scanned:

```powershell
smartctl --scan
```

Result:

```text
/dev/sda -d nvme # /dev/sda, NVMe device
/dev/sdb -d scsi # /dev/sdb, SCSI device
```

The mapping was interpreted as:

```text
/dev/sda    internal NVMe SSD
/dev/sdb    USB-connected FireCuda
```

The USB bridge exposed the FireCuda to Windows through a SCSI-style interface rather than directly as an ATA device.

---

## 8. Initial SMART Passthrough Attempt

The first generic SMART query was:

```powershell
smartctl -a /dev/sdb
```

Result:

```text
/dev/sdb: Unknown USB bridge [0x07ab:0xfc76]

Please specify device type with the -d option.
```

This identified the USB bridge as:

```text
VID:PID
07ab:fc76
```

but smartmontools did not automatically recognize the bridge implementation.

ATA/SAT passthrough was then attempted manually:

```powershell
smartctl -a -d sat /dev/sdb
```

An initial execution produced:

```text
Smartctl open device: /dev/sdb [SAT] failed:
\\.\PhysicalDrive1: Open failed, Error=5
```

PowerShell was reopened with administrative privileges.

Administrative access was verified with:

```powershell
net session
```

which returned:

```text
Es sind keine Einträge in der Liste.
```

The SMART command was then repeated:

```powershell
smartctl -a -d sat /dev/sdb
```

This time the physical device could be opened, but the bridge still failed to forward the required ATA command:

```text
Read Device Identity failed: SAT command failed

If this is a USB connected device, look at the various --device=TYPE variants

A mandatory SMART command failed: exiting.
```

Additional SAT command-length variants were also tested:

```powershell
smartctl -a -d sat,12 /dev/sdb
```

and:

```powershell
smartctl -a -d sat,16 /dev/sdb
```

Neither provided working ATA SMART passthrough.

---

## 9. SCSI Fallback Test

Because the bridge exposed the disk as a SCSI device, the generic SCSI backend was tested:

```powershell
smartctl -a -d scsi /dev/sdb
```

Result:

```text
=== START OF INFORMATION SECTION ===
Vendor:               ST2000LX
Product:              001-1RG174
Revision:             SDM1
User Capacity:        2.000.398.932.480 bytes [2,00 TB]
Logical block size:   512 bytes
scsiModePageOffset: response length too short, resp_len=4 offset=4 bd_len=0
scsiModePageOffset: response length too short, resp_len=4 offset=4 bd_len=0

Terminate command early due to bad response to IEC mode page
A mandatory SMART command failed: exiting.
```

This successfully confirmed the underlying physical drive identity and capacity.

The USB bridge therefore supports enough translation to expose:

* device vendor,
* device model,
* firmware revision,
* logical block size,
* and full disk capacity,

but does not provide the ATA/SAT commands required to retrieve the FireCuda's native SMART attribute table.

---

## 10. USB-to-SATA Bridge Limitation

The failure appears to be caused by the USB-to-SATA bridge rather than by the FireCuda itself.

The important observations are:

```text
USB bridge detected:            yes
Underlying disk detected:       yes
Correct model detected:         yes
Correct capacity detected:      yes
Partition table readable:       yes
NTFS filesystem readable:       yes
Normal file access:             yes
ATA SMART passthrough:          no
SCSI SMART/IEC pages:           incomplete
```

The bridge identifies itself as:

```text
07ab:fc76
```

and is reported by smartmontools as:

```text
Unknown USB bridge
```

Attempting SAT commands produces:

```text
Read Device Identity failed: SAT command failed
```

Using:

```text
-T permissive
```

could allow `smartctl` to continue past certain failed queries, but it would not add ATA command support that the bridge itself does not implement.

Full health validation therefore requires bypassing the current USB bridge.

---

## 11. Current Health Evidence

The following evidence currently supports the conclusion that the drive is functional:

| Test | Result |
|---|---|
| Drive powers on | Working |
| Drive spins | Working |
| USB bridge communication | Working |
| Device model detection | Working |
| Full 2 TB capacity detection | Working |
| Windows disk detection | Working |
| Disk online state | Working |
| GPT partition table | Valid |
| NTFS filesystem | Readable |
| Main data partition | Readable |
| Existing user data | None found |
| Windows health status | Healthy |
| Native SMART attributes | Not available through current bridge |
| Extended SMART self-test | Not performed |
| Full-surface validation | Not performed |

The current Windows health status is not sufficient to classify the physical disk as fully healthy.

The drive should therefore remain in:

```text
VALIDATION IN PROGRESS
```

rather than being marked as trusted storage.

---

## 12. Planned Native SATA Validation

The next test will connect the FireCuda directly to a desktop system.

The planned connection is:

```text
FireCuda
   │
   ├── SATA data  ──> motherboard SATA controller
   │
   └── SATA power ──> desktop PSU
```

This removes the USB translation layer and should allow smartmontools to communicate with the drive through its native ATA interface.

The first command after direct connection will be:

```powershell
smartctl --scan
```

Once the correct device has been identified, the full SMART report will be collected with:

```powershell
smartctl -a <device>
```

The following attributes are particularly important:

```text
Reallocated_Sector_Ct
Current_Pending_Sector
Offline_Uncorrectable
Power_On_Hours
UDMA_CRC_Error_Count
Temperature_Celsius
```

The SMART error log and existing self-test history should also be inspected.

---

## 13. Extended Self-Test

If the initial SMART report does not show critical problems, an extended SMART self-test should be started.

Example:

```powershell
smartctl -t long <device>
```

The expected completion time should be read from `smartctl` rather than assumed.

After the test has completed:

```powershell
smartctl -a <device>
```

or:

```powershell
smartctl -l selftest <device>
```

can be used to inspect the result.

A successful long self-test is particularly useful for an older salvaged HDD because Windows successfully mounting NTFS only proves that the structures and sectors accessed so far are readable.

It does not prove that the complete disk surface is healthy.

---

## 14. Deployment Criteria

The FireCuda should only be promoted to lab storage after the native SMART and extended self-test stages are complete.

A good result would ideally include:

```text
Reallocated sectors:     0
Pending sectors:         0
Offline uncorrectable:   0
SMART overall status:    passed
Extended self-test:      completed without error
```

Power-on hours will also be recorded to provide context for the age and previous usage of the disk.

Non-zero values do not automatically mean immediate failure, but reallocations, pending sectors, or uncorrectable sectors would significantly reduce confidence in the disk.

---

## 15. Intended Home-Lab Role

If validation succeeds, the FireCuda is a good candidate for non-critical bulk storage.

Potential roles include:

* ISO image storage,
* VM exports,
* archived VM images,
* packet captures,
* malware-lab artifacts,
* datasets,
* temporary backups,
* installation media,
* software repositories,
* log archives,
* and other replaceable large files.

The disk should not initially become the sole storage location for:

* unique project data,
* credentials,
* configuration backups,
* important documents,
* or anything that cannot be recreated.

The preferred role is therefore:

```text
bulk / archive / scratch storage
```

rather than:

```text
primary trusted backup
```

---

## 16. Related Hardware Discovery

The FireCuda was recovered as part of a larger collection of older hardware.

Other devices discovered during the same hardware salvage session include:

* Seagate IronWolf 4 TB 3.5-inch HDD,
* Seagate 2 TB 3.5-inch SSHD,
* Western Digital 500 GB 3.5-inch HDD,
* several older 2.5-inch laptop HDDs,
* Synology DS118 single-bay NAS,
* TP-Link TL-SG1008D 8-port Gigabit Ethernet switch,
* powered USB 3.0 hub,
* and older laptop memory modules.

The 3.5-inch drives cannot be tested with the current passive USB-to-SATA setup because they require an external 12 V supply.

They will be tested separately using either:

* direct SATA connections in a desktop system,
* a powered 3.5-inch SATA-to-USB adapter,
* a powered SATA dock,
* or another suitable SATA power source.

No storage device should be initialized or reformatted before its existing partition layout and data have been inspected.

---

## 17. Lessons Learned

The first useful lesson from the salvage session was that SATA data compatibility does not automatically imply SATA power compatibility.

The initial USB adapter successfully appeared in Windows while testing 3.5-inch drives, but reported a zero-byte device because the disk itself did not receive the required power.

A 2.5-inch SATA HDD such as the FireCuda could be powered successfully through the same general USB setup.

Other useful lessons were:

* distinguish 2.5-inch and 3.5-inch HDD power requirements before troubleshooting software,
* Windows detecting a USB storage bridge does not prove that the disk behind it is accessible,
* `HealthStatus: Healthy` from Windows is not a substitute for SMART analysis,
* salvaged disks should be inspected before initialization or formatting,
* check both normal and hidden files before deciding that an existing filesystem is empty,
* USB-to-SATA bridges vary significantly in ATA SMART passthrough support,
* an unknown USB bridge may still provide normal block-device access while blocking SMART commands,
* administrative privileges may be required for direct physical-disk access,
* SCSI inquiry information can still help identify a drive when ATA SMART passthrough fails,
* and direct SATA access remains useful when USB translation becomes the limiting factor.

The failed SMART attempts were therefore useful evidence rather than failed validation of the FireCuda itself.

They isolated the current USB bridge as the next technical limitation to remove.

---

## 18. Next Steps

### 18.1 Native SMART Inspection

Connect the FireCuda directly to the desktop SATA controller and collect:

```text
model
serial number
firmware version
SMART overall result
power-on hours
reallocated sectors
pending sectors
offline uncorrectable sectors
temperature
error log
self-test history
```

The serial number obtained through direct SATA should also be compared with:

```text
123400000022EAB
```

to determine whether the current value originates from the USB bridge.

### 18.2 Extended SMART Test

If the initial SMART report is acceptable:

```powershell
smartctl -t long <device>
```

Wait for the test to finish and record the final self-test result.

### 18.3 Surface Validation

If the extended SMART test succeeds, perform an additional read/surface validation before deploying the disk.

This should avoid destructive write testing until the drive has been fully classified and any remaining data-preservation concerns have been eliminated.

### 18.4 Final Classification

Assign one of the following states:

```text
UNTESTED
TESTING
HEALTHY
DEGRADED
RETIRED
DEPLOYED
```

The current state is:

```text
TESTING
```

### 18.5 Lab Integration

If the disk passes validation, define its permanent storage role and document:

* host system,
* mount point or storage identifier,
* filesystem,
* backup expectations,
* allowed workload types,
* monitoring method,
* and replacement policy.

---

## 19. Current Status

| Component | Status |
|---|---|
| FireCuda physical detection | Working |
| Correct model detection | Working |
| Correct ~2 TB capacity | Working |
| USB-to-SATA communication | Working |
| GPT partition table | Working |
| NTFS DATA volume | Working |
| Existing user files | None found |
| Hidden filesystem inspection | Completed |
| smartmontools installation | Completed |
| smartctl device discovery | Working |
| USB bridge identification | Completed |
| ATA SMART through USB | Unsupported / failing |
| SCSI identification | Working |
| Native SATA SMART report | Not started |
| Extended SMART self-test | Not started |
| Surface validation | Not started |
| Home-lab deployment | Pending validation |

---

## 20. Checkpoint Result

The salvaged Seagate FireCuda `ST2000LX001-1RG174` is functional enough to be detected, powered, partitioned, mounted, and read normally through the current USB-to-SATA adapter.

Windows detects the full approximately 2 TB capacity, the GPT partition table is valid, and the main NTFS `DATA` volume is essentially empty.

The current USB-to-SATA bridge, identified as `07ab:fc76`, does not provide working ATA/SAT SMART passthrough. Generic SCSI communication is sufficient to confirm the underlying FireCuda model, firmware revision, block size, and capacity, but not sufficient to retrieve the drive's native SMART health attributes.

The FireCuda therefore cannot yet be considered fully validated.

The next checkpoint is direct SATA attachment to a desktop system, followed by native SMART inspection and an extended SMART self-test.

If those tests succeed, the drive can be promoted to non-critical bulk storage for the home lab.

For now:

```text
ST2000LX001-1RG174
2 TB FireCuda SSHD

FUNCTIONAL:  YES
READABLE:    YES
EMPTY:       YES
SMART:       PENDING NATIVE SATA ACCESS
LAB STATUS:  VALIDATION IN PROGRESS
```
