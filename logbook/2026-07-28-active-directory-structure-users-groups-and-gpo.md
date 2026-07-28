# Active Directory Organizational Structure, Users, Groups and Group Policy

**Date:** 28 July 2026  
**System:** Dell OptiPlex 5070 Micro  
**Platform:** Proxmox VE 9.2  
**Domain controller:** VM 200, `dc01`  
**Client:** VM 220, `client01`  
**Domain:** `lab.test`  
**Goal:** Create the first Active Directory organizational structure, normal domain user, security group, and computer and user Group Policy Objects.

## 1. Starting Point

The following infrastructure was already available:

```text
Domain controller: DC01
Domain: lab.test
NetBIOS domain: LAB
Client: CLIENT01
Client IP: 10.20.0.20
Domain controller IP: 10.20.0.10
```

`CLIENT01` was already joined to the domain and its secure channel had been verified.

The first normal domain user and a basic Group Policy structure were created during this session.

## 2. Organizational Unit Structure

The following organizational units were created at the root of `lab.test`:

```text
Servers
Workstations
Groups
Service Accounts
Lab Users
```

The option to protect the organizational units from accidental deletion was enabled.

A custom OU could not be called `Users` because the domain already contains the built-in `Users` container.

The custom user OU was therefore named:

```text
Lab Users
```

## 3. Computer Object Organization

After joining the domain, `CLIENT01` was initially stored in the built-in:

```text
CN=Computers
```

container.

The computer object was moved into:

```text
OU=Workstations,DC=lab,DC=test
```

The resulting object path was:

```text
CN=CLIENT01,OU=Workstations,DC=lab,DC=test
```

`DC01` remained inside the default `Domain Controllers` OU because that OU has domain-controller-specific policy links.

## 4. First Normal Domain User

The first normal domain user was created inside:

```text
OU=Lab Users,DC=lab,DC=test
```

The account details were:

```text
Display name: Nyx Valborne
User logon name: nvalborne
UPN: nvalborne@lab.test
Legacy logon: LAB\nvalborne
```

A temporary password was configured during account creation.

The user was initially required to change the password at first logon.

## 5. Domain User Login Test

The new user successfully logged into `CLIENT01`.

The identity was verified using:

```powershell
whoami
```

The result was:

```text
lab\nvalborne
```

The domain was verified using:

```powershell
$env:USERDOMAIN
```

The result was:

```text
LAB
```

A local profile was created at:

```text
C:\Users\nvalborne
```

## 6. User Group Policy Processing Verification

Group Policy processing was checked with:

```powershell
gpresult /r
```

The result confirmed:

```text
CN=Nyx Valborne,OU=Lab Users,DC=lab,DC=test
```

The policy source was:

```text
DC01.lab.test
```

At this stage, no custom user Group Policy Object existed yet.

## 7. Security Group Creation

A new group was created inside:

```text
OU=Groups,DC=lab,DC=test
```

The group was configured as:

```text
Name: GG-Lab-Users
Scope: Global
Type: Security
```

The prefix `GG` represents a Global Group.

This naming convention makes the group purpose and scope visible in its name.

## 8. User Group Membership

Nyx Valborne was added to:

```text
GG-Lab-Users
```

Because Windows creates the user security token at logon, the membership did not appear in the existing session immediately.

After a complete sign-out and sign-in, the membership was verified with:

```powershell
whoami /groups | findstr /i "LAB"
```

The result included:

```text
LAB\GG-Lab-Users
```

This confirmed the following relationship:

```text
Nyx Valborne
→ GG-Lab-Users
```

## 9. Workstation Group Policy Object

A new Group Policy Object was created and linked to:

```text
OU=Workstations
```

The GPO was named:

```text
GPO-Workstations-Baseline
```

Because `CLIENT01` is stored in the Workstations OU, this GPO applies to its computer configuration.

## 10. Workstation Baseline Policies

The following computer policies were configured under:

```text
Computer Configuration
└── Policies
    └── Administrative Templates
        └── Windows Components
            └── Cloud Content
```

The configured policies were:

```text
Turn off Microsoft consumer experiences
Do not show Windows tips
Turn off cloud consumer account state content
```

The corresponding German administrative-template entries included:

```text
Microsoft-Anwenderfeatures deaktivieren
Windows-Tipps nicht anzeigen
Inhalte des Cloud-Verbraucherkontostatus deaktivieren
```

These policies reduce consumer suggestions, promotional content, and Windows tips on domain workstations.

## 11. Workstation GPO Verification

The workstation policy was refreshed using:

```powershell
gpupdate /force
```

The computer policy result was checked from an elevated PowerShell session:

```powershell
gpresult /r /scope computer
```

The applied Group Policy Objects included:

```text
GPO-Workstations-Baseline
Default Domain Policy
```

This confirmed:

```text
CLIENT01
→ Workstations OU
→ GPO-Workstations-Baseline
```

## 12. User Group Policy Object

A second Group Policy Object was created and linked to:

```text
OU=Lab Users
```

The GPO was named:

```text
GPO-Lab-Users-Baseline
```

This GPO applies to user objects stored in the Lab Users OU.

## 13. User Baseline Policy

A user-specific policy was configured under:

```text
User Configuration
└── Policies
    └── Administrative Templates
        └── Windows Components
            └── Cloud Content
```

The configured policy was:

```text
Turn off the Windows welcome experience
```

The German administrative-template entry was:

```text
Windows-Willkommensseite deaktivieren
```

This policy reduces post-update and device-setup welcome prompts for users in the Lab Users OU.

## 14. User GPO Verification

While logged in as Nyx, Group Policy was refreshed:

```powershell
gpupdate /force
```

The user policy result was checked with:

```powershell
gpresult /r /scope user
```

The applied Group Policy Objects included:

```text
GPO-Lab-Users-Baseline
```

The result also showed Nyx as a member of:

```text
GG-Lab-Users
```

This confirmed:

```text
Nyx Valborne
→ Lab Users OU
→ GPO-Lab-Users-Baseline
```

## 15. Current Active Directory Structure

```text
lab.test
├── Domain Controllers
│   └── DC01
├── Workstations
│   └── CLIENT01
├── Servers
├── Lab Users
│   └── Nyx Valborne
├── Groups
│   └── GG-Lab-Users
└── Service Accounts
```

## 16. Current Group Policy Structure

```text
OU=Workstations
└── GPO-Workstations-Baseline
    ├── Microsoft consumer experiences disabled
    ├── Windows tips disabled
    └── Cloud consumer account content disabled
```

```text
OU=Lab Users
└── GPO-Lab-Users-Baseline
    └── Windows welcome experience disabled
```

## 17. Verification Summary

| Check | Result |
|---|---|
| Custom OUs created | Complete |
| CLIENT01 moved to Workstations | Complete |
| Normal domain user created | Complete |
| Nyx domain login verified | Complete |
| Global security group created | Complete |
| Nyx added to GG-Lab-Users | Complete |
| Group membership token verified | Complete |
| Workstation GPO created | Complete |
| Workstation GPO linked | Complete |
| Workstation GPO applied | Complete |
| User GPO created | Complete |
| User GPO linked | Complete |
| User GPO applied | Complete |

## 18. Problems Encountered

1. A custom OU could not be named `Users` because the built-in Users container already existed.
2. The built-in Users container and the intended custom user OU initially caused confusion.
3. Group membership did not appear until the user signed out and signed back in.
4. `gpresult /scope computer` required elevated administrative privileges.
5. The first user GPO policy name differed from the expected English administrative-template entry.
6. The user account became temporarily difficult to access after password confusion and repeated login attempts.
7. Windows sometimes attempted to use stale saved credentials instead of the explicitly entered domain account.

All issues were resolved before the checkpoint.

## 19. Lessons Learned

Organizational units should separate users, computers, groups, servers, and service accounts by administrative purpose.

The built-in Users container is not the same as a custom organizational unit.

Computer objects can be moved into an OU so computer-targeted GPOs apply predictably.

Domain controllers should remain in the default Domain Controllers OU unless there is a deliberate policy design reason to move them.

Permissions and policies should be assigned to security groups rather than directly to individual users.

Windows builds group membership into the user security token at logon.

A full sign-out and sign-in is required after changing group membership.

Computer and user Group Policy settings are processed separately.

`gpresult /r /scope computer` requires elevation, while a normal user can inspect their own user policy results.

Group Policy links follow the OU location of the target object.

## 20. Backup Checkpoint

Manual backups were created before beginning remote-access VPN configuration.

Suggested backup notes were:

```text
fw01:
OPNsense baseline before WireGuard configuration
```

```text
dc01:
AD OUs, Nyx user, GG-Lab-Users and GPOs verified
```

```text
client01:
Domain join, group membership and user/computer GPOs verified
```

The backup filename already contains the backup date and time, so dates were not repeated in the note field.

## 21. Next Steps

The next planned task is to configure secure remote access through OPNsense.

The intended design is:

```text
Remote laptop or Kali VM
→ WireGuard tunnel
→ FRITZ!Box UDP port forwarding
→ OPNsense
→ internal lab network
```

The VPN should provide controlled remote access to:

```text
10.20.0.0/24
```

Access to the Proxmox management interface at:

```text
192.168.178.53
```

may also be added through explicit firewall and routing rules.

The Proxmox web interface must not be exposed directly to the internet.

Only the VPN endpoint should be reachable externally.
