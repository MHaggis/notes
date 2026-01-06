# MandatoryProfilePersistence

**NTUSER.MAN Registry Callback Bypass - Atomic Testing Tool**

A focused PowerShell TUI for testing EDR/SIEM detection coverage against the NTUSER.MAN mandatory profile persistence technique.

## The Technique

This technique exploits how Windows handles mandatory user profiles to achieve registry persistence **without triggering registry callbacks**.

### How It Works

1. **Normal Registry Writes**: When a process calls `RegSetValue` or `RegCreateKey`, EDR solutions monitoring via `CmRegisterCallbackEx` kernel callbacks are notified.

2. **NTUSER.MAN Bypass**: Windows loads `NTUSER.MAN` (mandatory profile) **instead of** `NTUSER.DAT` when present in a user's profile directory. The hive is loaded directly from disk - no registry API calls are made, and registry callbacks are **not triggered**.

```
Normal Registry Write:
  Process → RegSetValue → Kernel Callback → EDR SEES IT

NTUSER.MAN Technique:
  Write NTUSER.MAN → User Logon → Hive Loaded → EDR IS BLIND
```

### Attack Flow

1. Export target user's HKCU hive as `.reg` format
2. Add persistence entries (Run keys, COM hijacks, etc.)
3. Convert to binary hive format (using tools like HiveSwarming)
4. Write as `NTUSER.MAN` in target's `%USERPROFILE%` directory
5. Wait for user logon

### Constraints

- User hives are locked while the session is active
- Activation requires logoff/logon or reboot
- This is a **persistence** mechanism, not immediate execution

## Usage

```powershell
# Run the tool
.\MandatoryProfilePersistence.ps1
```

### Menu Options

| Option | Description |
|--------|-------------|
| 1 | Learn about the NTUSER.MAN technique |
| 2 | Recon - Scan for existing NTUSER.MAN files |
| 3 | Export current HKCU hive to .reg format |
| 4 | Create test NTUSER.MAN with persistence keys |
| 5 | **[ATOMIC]** Full attack simulation |
| 6 | Cleanup - Remove test artifacts |
| 7 | Detection validation checks |
| 8 | View test results |

## Detection Opportunities

### What Your EDR/SIEM Should Detect

| Indicator | Source |
|-----------|--------|
| File write to `NTUSER.MAN` in profile directory | Sysmon Event ID 11, EDR file monitoring |
| File write to `NTUSER.MAN` on roaming profile shares | Network file monitoring |
| Existence of `.MAN` files outside expected deployments | File baseline comparison |
| Hive load from unexpected `.MAN` file | Registry auditing, ETW |

### Detection Queries

**Sysmon (Event ID 11 - FileCreate)**
```
EventCode=11 AND TargetFilename="*\\Users\\*\\NTUSER.MAN"
```

**Splunk**
```spl
index=sysmon EventCode=11 TargetFilename="*NTUSER.MAN"
| stats count by Computer, User, Image, TargetFilename
```

**Elastic/EQL**
```
file where file.path : "*\\Users\\*\\NTUSER.MAN" and event.action == "creation"
```

**Microsoft Sentinel (KQL)**
```kql
DeviceFileEvents
| where FileName =~ "NTUSER.MAN"
| where FolderPath has "Users"
| project Timestamp, DeviceName, InitiatingProcessAccountName, 
          InitiatingProcessFileName, FolderPath
```

**Sigma Rule Concept**
```yaml
title: NTUSER.MAN File Creation
status: experimental
description: Detects creation of NTUSER.MAN file which may indicate mandatory profile persistence technique
logsource:
    product: windows
    category: file_event
detection:
    selection:
        TargetFilename|endswith: '\NTUSER.MAN'
        TargetFilename|contains: '\Users\'
    condition: selection
falsepositives:
    - Legitimate mandatory profile deployments (kiosk, shared workstations)
    - IT administration tools
level: high
tags:
    - attack.persistence
    - attack.t1547
```

## Reference

- **Blog Post**: [Registry Writes Without Registry Callbacks](https://deceptiq.com/blog/ntuser-man-registry-persistence) by DeceptIQ
- **Credit**: Windows security researcher Jonas L for highlighting this "intended functionality"

## Files

| File | Description |
|------|-------------|
| `MandatoryProfilePersistence.ps1` | Main TUI tool |
| `mpp_results.json` | Test results log (created on first run) |
| `backups/` | Directory for exported hives and baselines |

## Safety Notes

- The **Full Atomic Test** creates a marker file, NOT a valid hive
- This ensures the test is safe and won't break your system on logon
- The marker file will trigger file monitoring detection
- Always run **Cleanup** after testing

Always run in a lab.

## MITRE ATT&CK

- **Tactic**: Persistence
- **Technique**: T1547.001 - Boot or Logon Autostart Execution: Registry Run Keys / Startup Folder
- **Sub-technique consideration**: This technique modifies registry indirectly via hive replacement

## Author

@MHaggis

## Version

1.0

