# MORI v2.6.2 Adversarial Validation, v2.7 Regression Hardening, and Vendor Patch Verification

**Date:** 12 August 2026  
**Hypervisor:** Proxmox VE 9.2  
**Firewall:** OPNsense `fw01`  
**Guest OS:** Ubuntu Server 24.04 LTS  
**Vulnerable Kernel:** `6.8.0-116-generic`  
**Vendor-Patched Validation Kernel:** `6.8.0-137-generic`  
**Vendor Kernel Package Version:** `6.8.0-137.137`  
**Research Target:** `copyfail-vuln`  
**Primary Research User:** `researcher`  
**Unprivileged Test User:** `labuser`  
**Detection System:** MORI Monitor  
**Broad Compensating Control:** MORI Guard v1  
**Selective Compensating Control:** MORI v2.6.2 → v2.7  
**Current Project State:** Experimental work complete, evidence frozen, final technical report preparation  

---

## 1. Previous Checkpoint

The previous home-lab report ended after MORI v2 had already progressed through the major observer, correlation, shadow-policy and selective-enforcement stages.

By the time that report was complete, the lab had already established:

```text
MORI Monitor
        |
        v
integrity detection

MORI Guard v1
        |
        v
broad interface-level interruption

MORI v2
        |
        v
behavioral correlation
        |
        v
shadow policy
        |
        v
selective EPERM enforcement
        |
        v
structured telemetry
        |
        v
attacker-facing TTY notification
```

The current MORI build at that boundary was:

```text
MORI v2.6.2
```

The important gap was not another synthetic test.

It was much simpler:

```text
we had not yet given MORI v2.6.2
the real Copy Fail PoC
```

The controlled behavioral harnesses had demonstrated the selected policy boundary.

They had not yet proven that the complete original exploit path would actually be interrupted by the final v2.6.2 control.

That became the starting point of this checkpoint.

---

## 2. Goal of This Checkpoint

The goal of this phase was adversarial validation rather than feature development.

The questions became:

```text
Does MORI v2.6.2 stop the real Python Copy Fail PoC?

Does the result survive an independent C implementation?

Is the policy accidentally hard-coded around /usr/bin/su?

Does TGID-scoped state leak across processes?

Can the correlation state be bypassed through timing or lifecycle manipulation?

If MORI is hardened, do the real PoCs still fail?

Can the final implementation be frozen and tied to reproducible provenance?

Does the vendor-patched kernel independently stop the previously reproduced behavior?

Does the vendor remediation preserve benign AF_ALG AEAD functionality?
```

The development path therefore changed from:

```text
build feature
        |
        v
test feature
```

to:

```text
attack assumption
        |
        v
observe failure
        |
        v
change one thing
        |
        v
rerun the same regression
```

This became the defining methodology of the checkpoint.

---

## 3. Real Python Copy Fail PoC Against MORI v2.6.2

The first task was to remove the largest remaining validation gap.

Before execution, the vulnerable target state and active MORI v2.6.2 enforcement state were recorded.

The real Python Copy Fail proof of concept was then executed against the deliberately vulnerable system.

The exploit path that had previously produced local privilege escalation was interrupted.

MORI reached the correlated enforcement condition and returned:

```text
EPERM
```

The Python PoC terminated rather than completing the previously reproduced privilege transition.

The preserved evidence sequence was:

```text
39-mori-v2-6-2-pre-poc-validation.png
40-mori-v2-6-2-active-before-real-poc.png
41-mori-v2-6-2-real-copy-fail-poc-blocked.png
42-mori-v2-6-2-post-poc-validation-clean.png
```

Post-test validation showed that the privileged target remained clean.

The important progression was:

```text
synthetic policy harness
        |
        v
looked correct
        |
        v
real Python Copy Fail PoC
        |
        v
also denied
```

This was the first direct end-to-end validation of v2.6.2 against the original exploit family used in the lab.

---

## 4. Problem: One PoC Was Not Enough

The successful Python result immediately created another question.

A single implementation can accidentally become part of the policy assumptions.

The lab therefore needed to distinguish:

```text
"we block Copy Fail-relevant behavior"
```

from:

```text
"we block some implementation detail
of this Python script"
```

A separately compiled C implementation was introduced as an independent regression path.

The test sequence used the same defensive pattern:

```text
pre-state
    |
    v
independent C PoC
    |
    v
MORI decision
    |
    v
post-state
```

The C PoC was also denied.

The preserved evidence sequence was:

```text
43-mori-v2-6-2-c-poc-pre-state.png
44-mori-v2-6-2-c-poc-denied.png
45-mori-v2-6-2-c-poc-post-validation.png
```

The intended unauthorized privilege transition was not observed.

The target remained intact.

This strengthened the conclusion from:

```text
one PoC failed
```

to:

```text
two independently implemented tested PoC paths
failed under the selected control
```

---

## 5. Problem: Was MORI Really Protecting More Than `/usr/bin/su`?

Most earlier demonstrations had used:

```text
/usr/bin/su
```

as the controlled SUID target.

That made the experiment easy to compare across phases, but it also created the risk of accidentally developing a policy around one special path.

The test matrix was therefore expanded.

An alternate root-owned SUID target was first baselined using:

```text
fusermount3
```

A wider target sweep was then performed against accessible privileged executables.

The relevant evidence was:

```text
46-alternate-suid-target-baseline-fusermount3.png
47-mori-v2-6-2-suid-target-sweep-denied.png
48-mori-v2-6-2-post-suid-sweep-integrity-10-of-10.png
```

Post-test validation confirmed integrity for:

```text
10 of 10
```

checked targets.

This result must be interpreted carefully.

It does **not** prove that every tested SUID executable is independently exploitable through Copy Fail.

It demonstrates that MORI's selected policy was not implemented as a special-case rule for `/usr/bin/su`.

---

## 6. Cross-TGID Isolation

MORI's correlation model used process/TGID-scoped state.

That created an important negative-control requirement.

If one process generated AEAD-related state and another unrelated process later performed a privileged operation, their activities should not automatically combine into one policy decision.

A cross-TGID test intentionally separated relevant signals across distinct TGIDs.

The later operation remained allowed.

Evidence:

```text
49-mori-v2-6-2-cross-tgid-isolation-allowed.png
```

The tested behavior was therefore:

```text
TGID A
produces one tracked signal

TGID B
performs another operation
        |
        v
no accidental merged denial
```

This reduced the risk of cross-process state contamination in the tested model.

---

## 7. Problem: MORI v2.6.2 Could Be Bypassed Through State Expiry

After the real PoCs, alternate targets and cross-TGID isolation all behaved correctly, the control looked increasingly complete.

That was exactly the point at which the mitigation itself became the target.

A delayed same-TGID regression was designed to challenge the temporal assumptions behind MORI's correlation state.

The sequence deliberately created relevant state and then waited long enough for the original correlation window to expire before reaching the later protected operation.

The result was a real weakness in the v2.6.2 model.

Evidence:

```text
50-mori-v2-6-2-same-tgid-expiry-bypass-reproduced.png
```

The observed sequence was:

```text
same TGID
    |
    v
relevant state armed
    |
    v
delay
    |
    v
state expires
    |
    v
later protected operation
    |
    v
allowed
```

This was not a noisy log or cosmetic problem.

It demonstrated that the temporal policy could lose the context it depended on.

The project therefore moved from:

```text
v2.6.2 blocks the tested real PoCs
```

to:

```text
v2.6.2 blocks the tested real PoCs
but its state lifecycle contains a reproducible bypass condition
```

That distinction became one of the most important results of the project.

---

## 8. MORI v2.7 — First Regression Attempt Still Failed

MORI v2.7 was created to correct the lifecycle weakness.

The first attempt did not solve the problem.

The same regression was rerun and the splice path remained allowed.

Evidence:

```text
51-mori-v2-7-lifecycle-regression-splice-still-allowed.png
```

This was retained rather than hidden.

The version number had changed.

The security property had not yet changed.

That failure prevented the project from turning a code modification into an unsupported claim of remediation.

The workflow remained:

```text
same regression
        |
        v
same undesired behavior
        |
        v
fix not accepted
```

---

## 9. Lifecycle Redesign

The correlation lifecycle was then changed again.

The design problem was more subtle than simply increasing a timeout.

Relevant state needed to survive long enough to cover the tested operation sequence.

At the same time, completed activity could not leave permanent stale state that would later create false denials.

The desired lifecycle therefore became:

```text
relevant AF_ALG activity begins
        |
        v
tracked state becomes active
        |
        v
accepted / consumed lifecycle progresses
        |
        v
selected protected operation evaluated
        |
        v
state cleaned when lifecycle is genuinely complete
```

The previously reproduced same-TGID regression was then rerun.

This time the selected operation was denied.

Evidence:

```text
52-mori-v2-7-expiry-bypass-regression-fixed.png
```

The important result was not simply:

```text
timeout increased
```

It was:

```text
state lifetime redesigned
around the tested AF_ALG lifecycle
```

---

## 10. Problem: BPF Socket Pointer and Storage Handling

The lifecycle redesign required additional work around socket state.

The accept-side logic needed to determine whether an accepted connection belonged to a socket that MORI had already classified as relevant AF_ALG activity.

This created BPF-side pointer/storage handling problems during development.

The final implementation did not blindly classify every socket observed by the accept hook.

Instead, it checked MORI-associated storage on the **parent socket** before emitting tracked accept telemetry.

The final conceptual path became:

```text
socket accept
    |
    v
inspect parent socket
    |
    v
MORI storage present?
    |
    +---- no ----> ignore
    |
    `---- yes ---> tracked AF_ALG accept
```

The exact verifier/compiler diagnostic from the earlier failed implementation was not preserved in the final evidence package, so this report does not invent a specific verifier error string.

The supported conclusion is that accept-path implementation required reworking how BPF socket pointers and MORI socket storage were accessed before the final verifier-safe behavior was reached.

---

## 11. Problem: `socket_accept` Telemetry Became Noisy

Once accept observation existed, another problem appeared.

Ordinary socket activity began creating unrelated accept events.

System services and unrelated local communication could therefore pollute the trace.

The issue was not necessarily that enforcement had become incorrect.

The problem was observability:

```text
useful AF_ALG lifecycle event
        |
        +
ordinary system accepts
        |
        v
trace noise
```

The accept hook was therefore narrowed.

It now emits the relevant accept event only when the parent socket already carries MORI-tracked state.

The expected regression became:

```text
ordinary socket activity
        |
        v
no AEAD-ACCEPT spam


tracked AF_ALG AEAD bind/accept
        |
        v
AEAD-ACTIVE
AEAD-ACCEPT-OBSERVED
```

This change improved telemetry selectivity without changing the fundamental enforcement decision.

---

## 12. Problem: A Quiet Trace Could Also Mean a Broken Detector

Removing unwanted telemetry created its own test requirement.

A silent trace after the filter change was not sufficient evidence.

Silence could mean:

```text
noise removed
```

or:

```text
accept tracking accidentally broken
```

The regression therefore had to validate both sides:

| Test | Expected |
|---|---|
| Ordinary socket activity | No tracked AF_ALG accept event |
| Real tracked AF_ALG bind/accept | `AEAD-ACTIVE` and `AEAD-ACCEPT-OBSERVED` |

Only after both conditions behaved correctly was the telemetry filter treated as complete.

---

## 13. Problem: Stale Build Artifacts During BPF Iteration

MORI v2.7 was not one source file.

The final executable depended on a generated chain:

```text
mori_observer.bpf.c
        |
        v
mori_observer.bpf.o
        |
        v
mori_observer.skel.h
        |
        +
mori_observer.c
        |
        v
mori_observer.v2.7
```

During rapid iteration, this created a reproducibility risk.

A changed BPF source combined with an old skeleton or older userspace binary could result in testing a mixed-generation build.

The final candidate was therefore rebuilt transactionally.

Temporary outputs used:

```text
mori_observer.skel.h.new
mori_observer.v2.7.new
```

Each stage had to succeed and produce a non-empty result before replacing the previous file.

The candidate was then immediately fingerprinted.

This reduced the chance of accidentally validating stale generated artifacts.

---

## 14. Final MORI v2.7 Python PoC Retest

After the lifecycle correction and telemetry cleanup, the real Python PoC was returned to the test matrix.

The final v2.7 build denied the tested exploit path.

Evidence:

```text
53-mori-v2-7-final-python-poc-denied.png
54-mori-v2-7-final-python-post-validation.png
```

Post-test validation showed that the controlled privileged target remained intact.

This was important because the synthetic lifecycle regression alone was not treated as sufficient.

The final control had to survive both:

```text
mitigation-specific regression
        +
real exploit regression
```

---

## 15. Final Independent C PoC Retest

The independently compiled C implementation was then rerun against final v2.7.

The preserved source provenance was:

```text
Source:
/home/labuser/copyfail-c-test/exploit.c

SHA-256:
e1dec1348c0d43ab47d8f992d9a0336216fd37ff83e6fa1d9e39a80890fbd165
```

The binary provenance was:

```text
Binary:
/home/labuser/copyfail-c-test/copyfail-c

SHA-256:
3b2605dc5e820f40645f682385194469f9189cbb65ee99153b52aedf45be5706
```

Compiler:

```text
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
```

Evidence:

```text
55-mori-v2-7-final-c-poc-denied-and-post-validation.png
56-independent-c-poc-provenance.png
```

The intended unauthorized privilege transition was not observed.

The controlled target remained intact.

---

## 16. Judgment Cat and TTY Handling

The optional attacker-facing message remained part of the final MORI design.

The notification path searches:

```text
/proc/<tgid>/fd/
```

for a terminal associated with the originating process.

This introduced another implementation constraint.

A file descriptor is not automatically an interactive terminal.

Candidate descriptors therefore had to be opened and validated with:

```text
isatty()
```

If no suitable terminal existed, notification was skipped.

The architecture remained deliberately asymmetric:

```text
policy match
        |
        +----> BPF LSM returns -EPERM
        |
        `----> optional userspace notification
```

Notification failure could not weaken enforcement.

The ASCII cat remained presentation.

The BPF LSM decision remained the security control.

---

## 17. MORI v2.7 Artifact Freeze

After the final regressions passed, feature work stopped.

The validated implementation was frozen under:

```text
evidence/04-custom-mitigation/mori-v2/artifacts/current/
```

The frozen source set is:

```text
source/mori_observer.bpf.c
source/mori_observer.c
```

The frozen build set is:

```text
build/mori_observer.bpf.o
build/mori_observer.skel.h
build/mori_observer.v2.7
build/vmlinux.h
```

The implementation manifest contained six files.

All six passed SHA-256 verification.

The final executable hash is:

```text
7fe7b609b90e164f3ae4a9c025363399a8a63bf2a4338db2ecc62cfd2682d039
```

---

## 18. Problem: Two MORI Binaries Existed

The working directory contained both:

```text
mori_observer
mori_observer.v2.7
```

They had different sizes and different SHA-256 values.

This created an obvious provenance problem:

```text
which binary actually represents which version?
```

The older file:

```text
mori_observer
```

had SHA-256:

```text
cddd32cd62a4f6858f8ad4ae39f2e2bbe2100367530ac3f729b86d53b81116f9
```

It was compared directly against:

```text
checkpoints/v2.6.2/mori_observer
```

The files were byte-for-byte identical.

The ambiguity therefore became useful evidence:

```text
mori_observer
    -> historical v2.6.2 binary

mori_observer.v2.7
    -> final validated v2.7 binary
```

The old file was preserved rather than overwritten.

---

## 19. Final MORI Provenance

A dedicated provenance record was captured for the final package.

The recorded environment included:

```text
Host:
copyfail-vuln

Kernel at provenance capture:
6.8.0-137-generic

Compiler:
Ubuntu clang version 18.1.3

libbpf:
1.3.0
```

The record also contained the final executable hash and successful implementation-manifest verification.

`PROVENANCE.txt` had SHA-256:

```text
f6e51589f9d197f0d2f5a57a47814e2ddecd3b00524a5ab808e2af5f6a88aa15
```

After transfer to the Windows repository, the same hash was obtained.

This confirmed that the repository copy was byte-for-byte identical to the captured lab copy.

A local archival tarball was also created:

```text
mori-v2.7-final.tar.gz
```

with SHA-256:

```text
1b8baa3007e2214c1c878763ddc56efe3bfd716600b4f666c85f9b3bd555cc57
```

Verification returned:

```text
mori-v2.7-final.tar.gz: OK
```

The public repository retained the separated source/build tree rather than adding another duplicate archive.

---

## 20. Problem: We Nearly Duplicated the Final MORI Package

The frozen VM package initially suggested creating another:

```text
mori-v2.7/
```

directory in the repository.

The repository already contained:

```text
mori-v2/artifacts/current/
```

A second final package would have created duplicate evidence with unclear authority.

Instead of copying blindly, all six existing repository files were hashed and compared against the frozen VM set.

All six matched exactly.

The result was:

```text
repo current/
        ==
validated frozen v2.7 package
```

The existing structure was kept.

Only provenance material needed to be added.

---

## 21. Transition to Vendor Patch Validation

With the compensating control frozen, the next research phase was deliberately separated.

The question was no longer:

```text
can MORI contain the vulnerable environment?
```

It became:

```text
does the vendor-remediated kernel
independently prevent the reproduced behavior?
```

A new evidence phase was created:

```text
evidence/05-vendor-patch-validation/
```

The vendor validation used:

```text
Ubuntu 24.04.2 LTS
Linux 6.8.0-137-generic
linux-image-6.8.0-137-generic
Version 6.8.0-137.137
```

---

## 22. MORI Isolation

The patched kernel could not be evaluated while MORI was still making enforcement decisions.

Before the vendor retest, the active state was checked.

Validation confirmed:

```text
MORI processes:
none

MORI integrity service:
inactive

MORI BPF pins:
none
```

This created the required experimental separation:

```text
custom mitigation
        |
        X
        |
patched-kernel test
```

Any later failure of the Copy Fail PoCs could therefore be attributed to the tested patched environment rather than to MORI enforcement.

---

## 23. Benign AF_ALG Compatibility on the Patched Kernel

A patch test would be incomplete if the affected interface had simply disappeared.

The `algif_aead` functionality remained available.

A benign unprivileged AF_ALG AEAD lifecycle successfully completed:

```text
socket(AF_ALG): OK
bind(("aead", "gcm(aes)")): OK
accept(): OK
```

The compatibility result was important because MORI Guard v1 had already shown the weakness of a mitigation that stops the exploit by also stopping legitimate use.

The patched environment instead demonstrated:

```text
tested benign AEAD path
        -> preserved
```

while the subsequent exploit retests no longer reproduced the previous privilege transition.

---

## 24. Problem: The First Patched Python Test Was Invalid

The first Phase 05 Python attempt failed for the wrong reason.

The interpreter could not open the PoC file due to permissions.

That run did **not** test the vendor patch.

It only tested the filesystem permissions around the test script.

The artifact:

```text
phase05-patched-python-poc-invalid-permission.txt
```

was therefore excluded from the public Phase 05 evidence package.

The mistake was preserved privately as part of the research trail rather than being presented as successful mitigation evidence.

After the test setup was corrected, the actual Python PoC was executed.

The intended unauthorized privilege transition was not observed.

The test identity remained unprivileged.

The target retained its baseline integrity.

---

## 25. Patched Independent C Retest and Evidence-Provenance Problems

The independent C implementation was also used against the patched kernel.

The actual test result was clean:

```text
unauthorized privilege transition:
not observed

normal su authentication:
preserved

/usr/bin/su integrity:
preserved
```

The evidence collection around the test was less clean.

### 25.1 Placeholder Path

The first provenance screenshot still contained:

```text
/path/to/poc.c
```

This was not acceptable publication evidence.

The real source and binary were then located:

```text
exploit.c
copyfail-c
README.md
```

### 25.2 Source Accidentally Pointed to the Binary

The next provenance attempt accidentally used:

```text
copyfail-c
```

for both:

```text
SOURCE
BINARY
```

That error was caught before publication.

The correct source was:

```text
/home/labuser/copyfail-c-test/exploit.c
```

### 25.3 Misleading Provenance Header

The corrected provenance output initially used the title:

```text
MORI V2.7 INDEPENDENT C POC PROVENANCE
```

That wording was misleading because Phase 05 intentionally had MORI isolated.

The header was retaken as:

```text
PHASE 05 INDEPENDENT C POC PROVENANCE
```

The final evidence therefore represented the correct experiment rather than merely having correct hashes underneath a confusing title.

---

## 26. Final `/usr/bin/su` Integrity and Authentication Control

After the patched Python and C retests, the controlled target was validated again.

Its SHA-256 remained:

```text
c74311fe5636b7d7f9a56239fa8adeeab12ba86fe7d41b91afa85bf9bbdae78b
```

The target retained:

```text
root ownership
SUID mode 4755
expected file state
```

A normal unprivileged execution of:

```text
/usr/bin/su
```

reached the authentication boundary and returned:

```text
su: Authentication failure
```

An important interpretation error was corrected here.

The result does **not** mean:

```text
researcher cannot access /usr/bin/su
```

The user could execute the SUID program normally.

The security-relevant result was:

```text
normal authentication still enforced
        +
no unauthorized privilege transition observed
```

---

## 27. Problem: The Evidence Package Was Missing Its Raw Text Files

The Phase 05 screenshots were organized first.

Then the evidence tree revealed an obvious problem:

```text
screenshots/
    -> complete

artifacts/
    -> nearly empty
```

The machine-readable records were still sitting on the research VM.

The system was therefore searched for the real Phase 05 text artifacts.

The public set became:

```text
phase05-pre-patch.txt
phase05-vendor-patch-isolation.txt
phase05-patched-aead-control.txt
phase05-independent-c-poc-provenance.txt
phase05-final-target-validation.txt
```

Two files were deliberately excluded:

```text
phase05-patched-python-poc-invalid-permission.txt
```

because it represented the failed setup,

and:

```text
56-independent-c-poc-provenance.txt
```

because it belonged to the Phase 04 MORI validation sequence.

The result was a cleaner distinction between:

```text
raw machine-readable evidence
        +
visual interactive evidence
```

---

## 28. Problem: 19 Manifest Entries Instead of 18

The Phase 05 evidence should have contained:

```text
5 text artifacts
+
13 screenshots
=
18 evidence objects
```

The generated manifest contained:

```text
19
```

The extra entry was:

```text
README
```

The manifest filter excluded:

```text
README.md
```

but the documentation file was named simply:

```text
README
```

The README was renamed correctly and the manifest regenerated.

The final evidence scope became:

```text
artifacts/*
screenshots/*
```

while the editable documentation remained outside the evidence hash scope.

Final verification:

```text
18 / 18 OK
```

---

## 29. Problem: Phase 05 Was Initially Nested Inside Phase 04

The first directory layout accidentally placed:

```text
05-vendor-patch-validation
```

inside:

```text
04-custom-mitigation
```

That filesystem structure implied the vendor remediation was conceptually part of MORI.

It was corrected to:

```text
evidence/
├── 04-custom-mitigation/
└── 05-vendor-patch-validation/
```

This was more than cosmetic cleanup.

The directory structure now reflects two different research questions:

```text
04
Can a custom compensating control contain the vulnerable environment?

05
Does the vendor-remediated kernel solve the problem independently?
```

The final MORI artifact-provenance screenshot was also moved into the MORI-specific screenshot sequence as:

```text
57-mori-v2-7-final-artifact-provenance.png
```

The affected public manifests were regenerated afterward.

---

## 30. Final Phase 05 Evidence Package

The completed vendor-patch package contains:

```text
Raw text artifacts:  5
Screenshots:        13
Total evidence:     18
```

The screenshot sequence is:

```text
00-vendor-patch-baseline.png
01-vendor-patch-baseline-hash.png
02-mori-enforcement-isolated.png
03-vendor-kernel-package-version.png
04-algif-aead-module-state.png
05-benign-aead-control-pass.png
06-benign-aead-control-hash.png
07-python-poc-provenance-and-denial.png
08-post-python-target-integrity.png
09-pre-c-poc-target-integrity.png
10-independent-c-poc-provenance.png
11-independent-c-poc-denied.png
12-post-c-poc-integrity-auth-control.png
```

All 18 evidence objects passed manifest verification.

The final Phase 05 conclusion is intentionally scoped.

Within the tested environment and against the Python and independent C PoC implementations used in the lab:

```text
previous unauthorized privilege transition
        -> not reproduced

MORI enforcement
        -> absent

tested benign AF_ALG AEAD lifecycle
        -> operational

/usr/bin/su baseline integrity
        -> preserved

normal su authentication
        -> preserved
```

---

## 31. Repository Documentation Drift

The public repository README still reflected an earlier research state.

It contained outdated assumptions such as:

```text
MORI v2.6.2 = final
vendor patch validation = pending
final artifacts under final/
Phase 05 = upcoming
```

The root documentation was rewritten after the evidence freeze.

It now records:

```text
MORI v2.7 = current validated research control
same-TGID expiry weakness = reproduced
v2.7 lifecycle correction = completed
vendor patch validation = completed
artifacts/current/ = authoritative final MORI tree
Phase 05 = complete
```

The repository milestone was committed as:

```text
evidence: finalize MORI v2.7 and vendor patch validation
```

That commit marks the boundary between active experimental work and final report preparation.

---

## 32. Final Defensive Comparison

The complete lab now demonstrates four distinct states.

| State | Result | Compatibility |
|---|---|---|
| Vulnerable kernel, no mitigation | Copy Fail reproduced and UID 0 confirmed | Vulnerable interface available |
| MORI Guard v1 | Tested exploit path interrupted | Tested benign AEAD use also broken |
| MORI v2.7 | Tested correlated behavior and tested PoCs denied | Tested benign/negative-control behavior preserved |
| Vendor-remediated kernel | Tested Python and C PoCs no longer reproduced the previous privilege transition | Tested benign AF_ALG AEAD lifecycle remained operational |

The controls therefore have different roles:

```text
MORI Monitor
    -> detection

MORI Guard v1
    -> broad compensating control

MORI v2.7
    -> experimental selective compensating control

vendor kernel update
    -> preferred long-term remediation
```

MORI was intentionally not treated as a replacement for patching.

---

## 33. Updated Debugging Method

The earlier home-lab rule remained valid:

```text
observe first
change one thing
measure again
```

This checkpoint added two more rules:

```text
attack the mitigation
        +
preserve failed tests
```

The practical sequence became:

```text
1. Give v2.6.2 the real Python PoC
2. Confirm target integrity
3. Add an independent C PoC
4. Confirm target integrity again
5. Expand beyond /usr/bin/su
6. Test cross-TGID isolation
7. Design a same-TGID timing regression
8. Reproduce the expiry bypass
9. Attempt a lifecycle fix
10. Observe that the first v2.7 regression still fails
11. Redesign state lifecycle
12. Rerun the same regression
13. Fix accept-path socket-state handling
14. Remove unrelated accept telemetry
15. Confirm tracked AF_ALG accepts still appear
16. Rebuild the final candidate transactionally
17. Rerun real Python PoC
18. Rerun independent C PoC
19. Freeze implementation artifacts
20. Resolve old/new binary provenance
21. Capture final provenance
22. Isolate MORI
23. Validate vendor kernel/package
24. Confirm benign AF_ALG behavior
25. Reject an invalid Python test caused by permissions
26. Rerun the actual Python PoC
27. Correct C provenance mistakes
28. Rerun independent C PoC
29. Validate final SUID target
30. Recover raw text artifacts from the VM
31. Fix the evidence manifest
32. Separate Phase 04 and Phase 05
33. Regenerate manifests
34. Update public repository documentation
```

The lab increasingly treated failures as data rather than interruptions.

---

## 34. Problems Encountered

The most important problems during this checkpoint were:

| Problem | Effect | Resolution |
|---|---|---|
| v2.6.2 had never faced the real PoC | Validation gap | Real Python PoC added |
| One Python implementation might bias results | Implementation-specific confidence | Independent C PoC added |
| `/usr/bin/su` could become a hard-coded assumption | Narrow target confidence | Alternate SUID sweep |
| TGID state might leak between processes | False cross-process correlation | Cross-TGID negative control |
| Temporal state expired too early | Same-TGID bypass | v2.7 lifecycle redesign |
| First v2.7 regression still allowed splice | Initial fix insufficient | Lifecycle changed again |
| Socket accept state required careful BPF pointer/storage handling | Implementation/verifier difficulty | Parent-socket MORI storage used |
| Accept hook produced unrelated telemetry | Operational trace noise | Tracked-parent filter |
| Telemetry filter could accidentally hide all accepts | False confidence from silence | Positive + negative telemetry regression |
| Generated BPF artifacts could become stale | Mixed-generation build risk | Transactional rebuild |
| TTY notification could target wrong FD | Unreliable presentation path | `isatty()` validation |
| First patched Python run failed on file permissions | Invalid patch test | Excluded and rerun correctly |
| C provenance contained `/path/to/poc.c` | Invalid evidence | Correct source located |
| Source provenance pointed to binary | Wrong provenance | `exploit.c` captured |
| C provenance header implied MORI was active in Phase 05 | Ambiguous evidence | Phase 05-specific header |
| `su` result initially described as inaccessible | Incorrect interpretation | Normal authentication wording |
| Final MORI files risked being duplicated | Conflicting authoritative copies | Hash-compare existing `current/` |
| Old `mori_observer` identity unclear | Version ambiguity | Proven byte-identical to v2.6.2 |
| Phase 05 raw text artifacts missing from repo | Screenshot-heavy evidence | Five real artifacts recovered |
| Manifest contained 19 instead of 18 entries | Mutable README hashed | Rename/exclude README |
| Phase 05 nested under Phase 04 | Conceptual structure wrong | Separate sibling evidence phase |
| Moving evidence changed path-based manifests | Integrity metadata stale | Manifests regenerated |
| Root README reflected old state | Documentation drift | Full project README update |

The common pattern was:

```text
technical result
        |
        v
question the assumption behind it
        |
        v
find another edge case
        |
        v
make the evidence stronger
```

---

## 35. Current Status

| Component | Status |
|---|---|
| Vulnerable kernel `6.8.0-116-generic` | Preserved |
| Original Copy Fail reproduction | Confirmed |
| MORI Monitor | Completed |
| MORI Guard v1 | Completed |
| MORI v2.6.2 real Python PoC validation | Completed |
| Independent C PoC validation | Completed |
| Alternate SUID sweep | Completed |
| Cross-TGID isolation | Confirmed |
| Same-TGID expiry bypass | Reproduced |
| First v2.7 regression | Failed as expected / preserved |
| MORI v2.7 lifecycle correction | Completed |
| Accept-path telemetry filtering | Completed |
| Final Python PoC under v2.7 | Denied |
| Final C PoC under v2.7 | Denied |
| MORI artifact freeze | Completed |
| MORI provenance | Verified |
| Vendor-patched kernel `6.8.0-137-generic` | Validated |
| MORI isolated from patch test | Confirmed |
| Patched benign AEAD control | Passed |
| Patched Python PoC | Previous privilege transition not reproduced |
| Patched C PoC | Previous privilege transition not reproduced |
| Final `/usr/bin/su` integrity | Preserved |
| Phase 05 evidence package | 18 / 18 verified |
| Repository evidence restructure | Completed |
| Root README update | Completed |
| Experimental phase | Complete |
| Final technical report | Next |

---

## 36. Lessons Learned

The largest lesson from this checkpoint is that:

```text
"the exploit failed"
```

is not the same as:

```text
"the control is robust"
```

MORI v2.6.2 blocked the real tested Python PoC.

It blocked an independent C implementation.

It survived alternate-target testing.

It preserved cross-TGID isolation.

And it still had a reproducible lifecycle weakness.

The control only became stronger because the successful result was treated as the beginning of regression testing rather than the end.

Other useful lessons were:

- real PoCs should be reintroduced after synthetic policy development,
- independent implementations reduce confidence in implementation-specific artifacts,
- alternate targets expose hard-coded assumptions,
- negative controls are as important as positive blocks,
- TGID-scoped state requires explicit isolation testing,
- temporal windows can become bypass surfaces,
- increasing a timeout is not equivalent to designing a lifecycle,
- BPF state across socket lifecycle hooks requires careful pointer and storage handling,
- telemetry selectivity and enforcement correctness are separate concerns,
- a quieter trace needs a positive control to prove the detector still works,
- generated BPF skeletons create reproducibility risks during rapid iteration,
- enforcement must remain independent from userspace telemetry and presentation,
- invalid test setup must not be reinterpreted as security evidence,
- evidence labels matter because a correct hash under a misleading title is still misleading,
- authentication failure is different from inability to execute a SUID binary,
- provenance should resolve ambiguous historical binaries instead of deleting them,
- machine-readable evidence should accompany screenshots where it genuinely exists,
- manifests should protect evidence rather than mutable documentation,
- repository structure should reflect experimental boundaries,
- and vendor remediation should be validated with the custom control removed.

The progression that best summarizes the checkpoint is:

```text
it blocks the exploit
        |
        v
does it block another implementation?
        |
        v
does it generalize beyond one target?
        |
        v
does state leak between processes?
        |
        v
can the state expire at the wrong time?
        |
        v
can the fix itself survive the same regression?
        |
        v
can we freeze exactly what was tested?
        |
        v
does the vendor fix solve the problem without MORI?
```

That sequence turned the final MORI work into an adversarial test of the defensive control itself.

---

## 37. Next Steps

The active Copy Fail experiment is complete for the current milestone.

The next work is documentation.

The final technical report should now combine:

```text
vulnerability analysis
        |
        v
controlled reproduction
        |
        v
observable privileged-file effect
        |
        v
MORI Monitor
        |
        v
MORI Guard v1
        |
        v
compatibility failure
        |
        v
MORI v2 selective-control development
        |
        v
real PoC validation
        |
        v
regression discovery
        |
        v
MORI v2.7 lifecycle hardening
        |
        v
artifact provenance
        |
        v
vendor patch validation
        |
        v
comparative conclusion
```

The technical presentation can later reduce the same story to:

```text
reproduce
detect
mitigate broadly
break compatibility
mitigate selectively
break the mitigation
fix the mitigation
validate the vendor patch
```

No additional exploit development is required for this checkpoint.

---

## 38. Checkpoint Result

Since the previous home-lab report, the Copy Fail project moved from a selective control that had been validated mainly with controlled behavioral harnesses into a fully adversarially tested mitigation and vendor-remediation study.

MORI v2.6.2 was first given the real Python Copy Fail PoC and denied the tested attack.

An independent C implementation was then added and also denied.

The test matrix expanded beyond `/usr/bin/su`, preserving integrity across a broader SUID-target sweep.

Cross-TGID testing showed that process-scoped state remained isolated in the tested negative control.

The next tests intentionally attacked MORI's own assumptions.

A delayed same-TGID sequence reproduced a state-expiry bypass in v2.6.2.

The first v2.7 regression still allowed the protected operation, proving that the initial change was insufficient.

The state lifecycle was then redesigned and the same regression was denied.

During this work, socket lifecycle handling introduced additional BPF pointer/storage complexity, and accept telemetry became noisy enough to require parent-socket state filtering.

The filtered telemetry was then validated with both negative and positive socket controls.

The final v2.7 build was rebuilt transactionally and tested again with the real Python and independent C PoCs.

Both tested paths were denied and the privileged target remained intact.

The implementation was then frozen, hashed and tied to explicit provenance.

An older ambiguous binary was proven byte-for-byte identical to the v2.6.2 checkpoint, while the final `mori_observer.v2.7` binary received its own distinct hash and preserved build record.

The project then moved from compensating-control research to vendor remediation.

MORI was removed from the active enforcement path.

The vendor-patched `6.8.0-137-generic` environment preserved the tested benign AF_ALG AEAD lifecycle while both the Python and independent C Copy Fail implementations failed to reproduce the previous unauthorized privilege transition.

The final `/usr/bin/su` hash remained identical to baseline and ordinary authentication behavior remained intact.

The Phase 05 evidence package was completed with five raw text artifacts, thirteen screenshots and an 18-of-18 verified SHA-256 manifest.

Several evidence mistakes were caught during packaging, including an invalid Python permission test, a placeholder C source path, incorrect source labeling, a misleading provenance title, a manifest accidentally hashing the README and an initially incorrect directory hierarchy.

Those mistakes were corrected before the final repository milestone was committed.

The current project state is therefore:

```text
Copy Fail reproduction          complete
MORI detection                  complete
MORI Guard v1                   complete, intentionally broad
MORI v2.6.2 real-PoC testing    complete
MORI self-regression testing    complete
same-TGID expiry weakness       reproduced
MORI v2.7 lifecycle fix         complete
final Python/C validation       complete
artifact provenance             complete
vendor patch validation         complete
evidence freeze                 complete
repository milestone            committed
final technical report          next
```

The final lesson is no longer simply:

```text
MORI can stop the tested exploit
```

It is:

```text
a compensating control should be treated
as another security-critical system
that deserves its own adversarial testing,
regression suite, provenance,
and eventual retirement once the
actual vendor remediation is available
```
