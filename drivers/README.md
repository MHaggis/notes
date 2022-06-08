# Hunting Windows U-boats with Cyber Depth Charges

- [RSA DarkArts Slides](RSA_DarkArts22_Hunting%20Windows%20U-boats%20with%20Cyber%20Depth%20Charges.pdf)
- [Splunk Driver Dashboard](splunk_driver_dashboard)


- [Hunting Windows U-boats with Cyber Depth Charges](#hunting-windows-u-boats-with-cyber-depth-charges)
  - [Known Vulnerable Drivers](#known-vulnerable-drivers)
  - [Extras](#extras)
    - [Safe mode bootup services/drivers](#safe-mode-bootup-servicesdrivers)
    - [ASR Audit Mode](#asr-audit-mode)
  - [References](#references)

**Abstract**


As defenders, a lot of our time is focused on the most common ATT&CK techniques seen daily and weekly. Underneath common privilege escalation and defense evasion lies a deeper dark art - Windows rootkits. Rootkits are hard to identify as they can reside in the user or kernel level, or lower. The most advanced adversaries will persist and hijack systems using rootkits. As a defender, how do we hunt, where do we hunt and what do we hunt? The attendee will leave with an understanding of Windows driver rootkits, how to identify suspicious drivers, and what to do about rootkits today. 


**Flow**

- Introduction
- What we will cover, what we will not (drivers yes, linux no)
	- problem statement:
	- Hunting drivers is hard. 
- Objectives
	- what to hunt, where to hunt, how to hunt
- What is a Windows Rootkit? - define .sys/windows drivers
- What do Drivers buy an adversary?
	- EDR Blind
		- Windows logs
- How to load a driver
- SignTool
- What to hunt
	- Driver Signing Status
		- digsig_result: Digital signature status: One of Signed, Unsigned, Expired, Bad Signature, Invalid Signature, Invalid Chain, Untrusted Root, Explicit Distrust
		- https://www.engadget.com/microsoft-signed-netfilter-malware-driver-164228266.html
			- Microsoft signed a driver loaded with rootkit malware
	- Signed Drivers 
		- 64 bit
		- Daxin rootkit
		- https://decoded.avast.io/martinchlumecky/dirtymoe-3/
	- Unsigned Drivers
		- 32 bit
	- Digsig_result
	- digsig_publisher
	- digsig_issuer
		- Signers gone bad
	- digsig_subject
	- digsig_sign_time
		- First time seen, old sign time
	- Paths
- Where to hunt
	- EDR
	- path
	- filemods
	- Registry
		- safeboot registry mod
		- Machine\\System\\CurrentControlSet\\Services
			- https://public.cnotools.studio/bring-your-own-vulnerable-kernel-driver-byovkd/utilities/loading-device-driver
- How to hunt
	- driver prevalence 
	- ntoskrnl loads
- A note on hunting drivers
	- problem statement: did we solve our problem?
	- Extreme needle in the haystack.
- Driver inventory
- Driver signing enforcement
	- Any other Windows features
- ASR


## Known Vulnerable Drivers
- https://github.com/secdev-01/physmem_drivers
- https://github.com/eclypsium/Screwed-Drivers
- https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/microsoft-recommended-driver-block-rules
- https://www.rapid7.com/blog/post/2021/12/13/driver-based-attacks-past-and-present/
- https://guidedhacking.com/threads/vulnerable-kernel-drivers-for-exploitation.15979/
- https://decoded.avast.io/martinchlumecky/dirtymoe-3/

Items not mentioned

There are definitely a few things I wish I was able to get in the content but was unable to due to time constraints. 
- Volatility
- Linux rootkits
- Newer Windows Kernel features

## Extras

### Safe mode bootup services/drivers

https://github.com/redcanaryco/atomic-red-team/pull/1832

`Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Minimal -Recurse`


### ASR Audit Mode
https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/attack-surface-reduction-rules-reference?view=o365-worldwide#block-abuse-of-exploited-vulnerable-signed-drivers

`Add-MpPreference -AttackSurfaceReductionRules_Ids 56a863a9-875e-4185-98a7-b882c64b5ce5 -AttackSurfaceReductionRules_Actions AuditMode`

ASR Audit logs

Event Viewer > Application and Services. > Windows > Widnows Defender > Operational > 1125/1126 for Event IDS 1121/1122 EVENTID
https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/enable-attack-surface-reduction?view=o365-worldwide#group-policy
https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/attack-surface-reduction-rules-reference?view=o365-worldwide


## References

- https://github.com/redcanaryco/AtomicTestHarnesses/tree/master/TestHarnesses/T1543.003_WindowsService
- https://www.fuzzysecurity.com/tutorials/28.html
- https://posts.specterops.io/code-signing-certificate-cloning-attacks-and-defenses-6f98657fc6ec
- https://gist.github.com/MHaggis/9ab3bb795a6018d70fb11fa7c31f8f48
- https://symantec-enterprise-blogs.security.com/blogs/threat-intelligence/daxin-backdoor-espionage
- https://redcanary.com/blog/tracking-driver-inventory-to-expose-rootkits/
- https://www.matteomalvica.com/blog/2020/07/15/silencing-the-edr/
- https://github.com/uf0o/windows-ps-callbacks-experiments/tree/master/evil-driver
- https://synzack.github.io/Blinding-EDR-On-Windows/
- https://github.com/PowerShell/PowerShell/blob/master/tools/Sign-Package.ps1
- https://docs.microsoft.com/en-us/powershell/module/dism/get-windowsdriver?view=windowsserver2022-ps
- index=win EventCode=7045 | stats values(Service_File_Name)
- WDAC - https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/wdac-wizard
- AppLocker
- Windows ASR - https://call4cloud.nl/2020/07/the-magnificent-asr-rules/#part5
- https://www.reddit.com/r/crowdstrike/comments/t81heu/2022a0306_cool_query_friday_situational_awareness/
- https://github.com/tandasat/ExploitCapcom
- https://posts.specterops.io/mimidrv-in-depth-4d273d19e148
- https://gorkemkaradeniz.medium.com/defeating-runasppl-utilizing-vulnerable-drivers-to-read-lsass-with-mimikatz-28f4b50b1de5
- https://github.com/MHaggis/gdrv-loader
- https://docs.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection
- https://redcanary.com/blog/ms-driver-block-rules/
- https://github.com/eclypsium/Screwed-Drivers
- https://eclypsium.com/wp-content/uploads/2019/08/EXTERNAL-Get-off-the-kernel-if-you-cant-drive-DEFCON27.pdf
- https://posts.specterops.io/threat-detection-using-windows-defender-application-control-device-guard-in-audit-mode-602b48cd1c11
- https://github.com/secdev-01/CVE-2020-15368
- https://www.unknowncheats.me/forum/anti-cheat-bypass/253258-vulnerable-driver-scanner.html
- https://www.rapid7.com/blog/post/2021/12/13/driver-based-attacks-past-and-present/