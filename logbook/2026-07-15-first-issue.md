## Initial Hardware Test and Defective Memory Diagnosis

**Date:** 15 July 2026
**System:** Dell OptiPlex 5070 Micro
**Planned configuration:** 32 GB RAM, 1 TB SSD
**Test objective:** Verify that the system and installed hardware function correctly before installing Proxmox and configuring the home lab.

## 1. Initial Test

After receiving the Dell OptiPlex, I performed an initial startup test to verify that the system booted correctly and recognized the installed hardware.

During startup, the system reported a memory-related hardware error. The full 32 GB of installed RAM was not available, indicating a possible issue with one of the following components:

* a memory module,
* a memory slot,
* or the physical connection between the module and the slot.

The system contained two 16 GB RAM modules installed in the available memory slots.

## 2. Troubleshooting Procedure

To identify the source of the error, I performed the following steps:

1. Powered down the system completely.
2. Disconnected the system from its power supply.
3. Opened the case and removed both RAM modules.
4. Inspected the modules and slots for visible damage or contamination.
5. Reinserted both modules to rule out an improperly seated connection.
6. Restarted the system and checked whether the memory error remained.
7. Swapped the two RAM modules between the available slots.
8. Restarted the system again and observed the diagnostic result.
9. Tested the modules individually to determine whether the error was associated with a specific RAM module or motherboard slot.

## 3. Test Results

Both memory slots successfully operated with the functional RAM module.

The memory error followed one specific 16 GB RAM module when the modules were exchanged between the two slots. The error therefore did not remain associated with a particular motherboard slot.

This test result indicates that:

* both motherboard memory slots are functional,
* one 16 GB RAM module is functional,
* and the second 16 GB RAM module is defective.

## 4. Diagnosis

The failure was isolated to one of the installed 16 GB RAM modules.

The motherboard, system, and memory slots appear to function correctly. The defective module prevents the system from reliably operating with the intended 32 GB memory configuration.

**Final diagnosis:** Defective 16 GB RAM module.

## 5. Current System Status

| Component                          | Status              |
| ---------------------------------- | ------------------- |
| Dell OptiPlex 5070 Micro           | Functional          |
| 1 TB SSD                           | No issue identified |
| Memory slot 1                      | Functional          |
| Memory slot 2                      | Functional          |
| RAM module 1                       | Functional          |
| RAM module 2                       | Defective           |
| Intended memory capacity           | 32 GB               |
| Currently verified memory capacity | 16 GB               |

## 6. Customer Support and Return

The issue was reported to customer service. The troubleshooting process and the suspected defective RAM module were explained.

Customer service requested that the system be returned for inspection or replacement. The return process must therefore be completed before the home-lab setup can continue with the intended hardware configuration.

## 7. Next Steps

1. Document the physical condition of the system before shipping.
2. Photograph the system, RAM modules, serial numbers, and packaging.
3. Package the system securely.
4. Return the system according to the seller’s instructions.
5. Test the repaired or replacement system after it is received.
6. Confirm that the full 32 GB of RAM is recognized.
7. Run an extended memory test.
8. Continue with the Proxmox installation after the hardware has passed testing.

## 8. Lessons Learned

Testing hardware before installing the operating system prevented a defective component from causing problems later in the home-lab setup.

Swapping the RAM modules between known-working slots made it possible to distinguish between a defective memory slot and a defective memory module. Because the error followed the module, the defective component could be identified with reasonable confidence.

This incident also demonstrates the importance of documenting hardware tests, troubleshooting steps, and communication with the seller from the beginning of a home-lab project.
