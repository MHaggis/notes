# Building Splunk+BOTS

What is BOTS?


## Decisions to be made

- [ ] Which BOTS?
- [ ] Where to build at?
  - [ ] Vultr.com 
  - [ ] Digitalocean.com
  - [ ] AWS
  - [ ] DetectionLab
  - [ ] LocalVM


## Apps Needed

| App / Add-on | Version | Download |
| ----------- | ------- | -------- |
| Splunk Enterprise | 6.5.2 | http://www.splunk.com
| Fortinet Fortigate Add-on for Splunk | 1.3 |https://splunkbase.splunk.com/app/2846
| Splunk Add-on for Tenable |5.0.0 | https://splunkbase.splunk.com/app/1710/ |Note v5.0.0 is no longer publicly available. Use v5.1.1 instead.
| Splunk Stream Add-on (Note Stream 6.6.1 is no longer available. Use Version 7.1.1 instead.) | 6.6.1 |https://splunkbase.splunk.com/app/1809/ 
| Splunk App for Stream (Note Stream 6.6.1 is no longer available. Use Version 7.1.1 instead.) | 6.6.1 | https://splunkbase.splunk.com/app/1809/
| Splunk Add-on for Microsoft Windows | 4.8.3 | https://splunkbase.splunk.com/app/742/
| TA-Suricata | 2.3 | https://splunkbase.splunk.com/app/2760/
| Microsoft Sysmon Add-on | 3.2.3 | https://splunkbase.splunk.com/app/1914/
| URL Toolbox | 1.6 |https://splunkbase.splunk.com/app/2734/
| Splunk Enterprise                               | 7.2.1  | http://www.splunk.com
| SA-Investigator                                 | 1.3.1  | https://splunkbase.splunk.com/app/3749/
| Base64	                                        | 1.1	   | https://splunkbase.splunk.com/app/1922/
| URL Toolbox	                                    | 1.6	   | https://splunkbase.splunk.com/app/2734/
| Splunk Security Essentials                      | 2.3.0  | https://splunkbase.splunk.com/app/3435/
| JellyFisher	                                    | 0.1.0  | https://splunkbase.splunk.com/app/3626/
| Splunk Common Information Model	                | 4.12.0 | https://splunkbase.splunk.com/app/1621/
| Splunk Add-on for Apache                        | 1.0.0	 | https://splunkbase.splunk.com/app/3186/
| Splunk Add-on for Microsoft Cloud Services      | 2.0.3  | https://splunkbase.splunk.com/app/3110/
| Palo Alto Networks Add-on for Splunk            | 3.8.2	 | https://splunkbase.splunk.com/app/2757/
| Splunk Add-on for Symantec Endpoint Protection  | 2.3.0	 | https://splunkbase.splunk.com/app/2772/
| TA-Suricata	                                    | 2.3.3	 | https://splunkbase.splunk.com/app/2760/
| Microsoft Sysmon Add-on	                        | 6.0.4	 | https://splunkbase.splunk.com/app/1914/
| Collectd App for Splunk Enterprise              | 1.1    | https://splunkbase.splunk.com/app/2875/
| OSquery                                         |	1      | https://splunkbase.splunk.com/app/3278/
| SSL Certificate Checker                         | 3.2	   | https://splunkbase.splunk.com/app/3172/
| Website Monitoring	                            | 2.5    | https://splunkbase.splunk.com/app/1493/	
| Splunk Add-on for Microsoft IIS                 | 1.0.0	 | https://splunkbase.splunk.com/app/3185/
| Splunk Add-on for Unix and Linux                | 6.0.0  | https://splunkbase.splunk.com/app/833/
| Splunk Stream Add-on                            | 7.1.1  | https://splunkbase.splunk.com/app/1809/
| Splunk Add-on for Microsoft Windows             | 5.0.1  | https://splunkbase.splunk.com/app/742/
| Splunk Enterprise                               | 7.1.7 | http://www.splunk.com
|	Aws_guardduty	                                  |	1.0.4	|	https://splunkbase.splunk.com/app/3790/
|	CiscoNVM	                                      |	1.0.346	|	https://splunkbase.splunk.com/app/2992/
|	Code42 App For Splunk	                          |	3.0.6	|	https://splunkbase.splunk.com/app/3736/
|	Code42ForSplunk Technology Add-On	              |	3.0.4	|	https://splunkbase.splunk.com/app/3746/
|	Splunk Add-on for Cisco ASA	                    |	3.3.0	|	https://splunkbase.splunk.com/app/1620/
|	Splunk Add-on for Microsoft Cloud Services	    |	2.1.0	|	https://splunkbase.splunk.com/app/3110/
|	Splunk Add-on for Microsoft Office 365	        |	1.0.0	|	https://splunkbase.splunk.com/app/4055/
|	Splunk Add-on for Microsoft Windows	            |	4.8.4	|	https://splunkbase.splunk.com/app/742/
|	Splunk Add-on for Symantec Endpoint Protection	|	2.3.0	|	https://splunkbase.splunk.com/app/2772/
|	Splunk Add-on for Tenable	                      |	5.1.3	|	https://splunkbase.splunk.com/app/1710/
|	Splunk Add-on for Unix and Linux	              |	5.2.4	|	https://splunkbase.splunk.com/app/833/
|	Splunk Common Information Model	                |	4.11.0	|	https://splunkbase.splunk.com/app/1621/
|	Splunk Security Essentials	                    |	2.2.0	|	https://splunkbase.splunk.com/app/3435/
|	Splunk Stream Add-on	                          |	7.1.2	|	https://splunkbase.splunk.com/app/1809/
|	TA-VirusTotalActions	                          |	0.2.0	|	https://splunkbase.splunk.com/app/3446/
|	URL Toolbox	                                    |	1.6	  |	https://splunkbase.splunk.com/app/2734/
|	DecryptCommands	                                |	2	|	https://splunkbase.splunk.com/app/2655/
|	Microsoft Azure Active Directory Reporting Add-on for Splunk	|	1.0.1	|	https://splunkbase.splunk.com/app/3757/
|	Microsoft Cloud App for Splunk	                |	1.0.1	|	https://splunkbase.splunk.com/app/3786/
|	Microsoft Office 365 Reporting Add-on for Splunk  |	1.0.1	|	https://splunkbase.splunk.com/app/3720/
|	Microsoft Sysmon Add-on	                        |	8.0.0	|	https://splunkbase.splunk.com/app/1914/
|	OSquery App for Splunk	                        |	0.6.0	|	https://splunkbase.splunk.com/app/3902/
|	Splunk Add-on for AWS	                          |	4.5.0	|	https://splunkbase.splunk.com/app/1876/
|	ES Content Updates	                            |	1.0.25	|	https://splunkbase.splunk.com/app/3449/
|	SA-cim_vladiator	                              |	1.2	|	https://splunkbase.splunk.com/app/2968/

## Installation
1. Download the dataset file.
2. Install Splunk Enterprise and the apps/add-ons listed. It is important to match the specific version of each app and add-on (ish).
3. Unzip/untar the downloaded file into $SPLUNK_HOME/etc/apps
4. Restart Splunk

_Note: that because the data is distributed in a pre-indexed format, there are no volume-based licensing limits to be concerned with._

## BOTSV1

### The Story

### Get it

- Download the dataset from this location: [botsv1_data_set.tgz](https://s3.amazonaws.com/botsdataset/botsv1/splunk-pre-indexed/botsv1_data_set.tgz) (6.1GB compressed)
- Alternatively, this collection represents a much smaller version of the original dataset containing only attack data. In other words, "just the needles, no haystack." [botsv1-attack-only.tgz](https://s3.amazonaws.com/botsdataset/botsv1/botsv1-attack-only.tgz)(135MB compressed)

May also dowload full json or individual json and csv per source.
- Download the JSON-formatted complete dataset from this location: [botsv1.json.gz](https://s3.amazonaws.com/botsdataset/botsv1/botsv1.json.gz) (11.3GB compressed, ~120GB uncompressed)

Walkthrough:
- [Boss of the SOC (BOTS)v1 Investigation Workshop for Splunk - SplunkBase](https://splunkbase.splunk.com/app/3985/)
- [Introducing the Security Datasets Project Splunk](https://www.splunk.com/en_us/blog/security/introducing-the-security-datasets-project.html)

### Install

[Easy install script](install_splunk_botsv1.sh)

One liner:

`wget -O - https://raw.githubusercontent.com/MHaggis/notes/master/Splunk%2BBOTS_build/install_splunk_botsv1.sh | bash`


### Whats included?

* WinEventLog:Application
* WinEventLog:Security
* WinEventLog:System
* XmlWinEventLog:Microsoft-Windows-Sysmon/Operational
* fgt_event
* fgt_traffic
* fgt_utm
* iis
* nessus:scan
* stream:dhcp
* stream:dns
* stream:http
* stream:icmp
* stream:ip
* stream:ldap
* stream:mapi
* stream:sip
* stream:smb
* stream:snmp
* stream:tcp
* suricata
* winregistry

`index=botsv1 earliest=0`

### References

- [Splunk BOTSv1 - Github](https://github.com/splunk/botsv1)
- [Boss Of The SOC v1 - Splunk](https://www.splunk.com/en_us/blog/security/boss-of-the-soc-scoring-server-questions-and-answers-and-dataset-open-sourced-and-ready-for-download.html)

## BOTSv2

### The Story


### Get it

| Dataset          | Description | Size | Format | MD5 | 
| ---------------- | ----------- | ---- | ------ | --- |
| [BOTS V2 Dataset](https://s3.amazonaws.com/botsdataset/botsv2/botsv2_data_set.tgz) |  Full BOTSv2 dataset. | 16.4GB | Pre-indexed Splunk | b9ddea9c2667348d45810ef1d260897a |
| [BOTS V2 Dataset (Attack Only)](https://s3.amazonaws.com/botsdataset/botsv2/botsv2_data_set_attack_only.tgz) | BOTSv2 "attack-only" dataset. This dataset contains minimal non-attack-related (aka "clean") data. It's everything you need and nothing you don't! | 3.2GB | Pre-indexed Splunk | 6f3984c4f039c0c9ee52feb3dc0e7340 | 

### Install

[Easy install script](install_splunk_botsv2.sh)

One liner:

`wget -O - https://raw.githubusercontent.com/MHaggis/notes/master/Splunk%2BBOTS_build/install_splunk_botsv2.sh | bash`

### Whats included?

* access_combined
* activedirectory
* apache:error
* apache_error
* auditd
* bandwidth
* collectd
* cpu
* csp-violation
* df
* ess_content_importer
* hardware
* interfaces
* iostat
* lastlog
* linux:selinuxconfig
* linux_audit
* linux_secure
* ms:o365:management
* msad:nt6:health
* msad:nt6:siteinfo
* mysql:connection:stats
* mysql:database
* mysql:errorlog
* mysql:instance:stats
* mysql:server:stats
* mysql:status
* mysql:table_io_waits_summary_by_index_usage
* mysql:tablestatus
* mysql:transaction:details
* mysql:transaction:stats
* mysql:user
* mysql:variables
* mysqld-8
* netstat
* openports
* osquery_info
* osquery_results
* osquery_warning
* package
* pan:system
* pan:threat
* pan:traffic
* perfmon:cpu
* perfmon:logicaldisk
* perfmon:memory
* perfmon:network
* perfmon:network_interface
* perfmon:ntds
* perfmon:physicaldisk
* perfmon:process
* perfmon:processor
* perfmon:system
* powershell:scriptexecutionsummary
* protocol
* ps
* script:installedapps
* script:listeningports
* stream:arp
* stream:dhcp
* stream:dns
* stream:ftp
* stream:http
* stream:icmp
* stream:ip
* stream:irc
* stream:ldap
* stream:mysql
* stream:smb
* stream:smtp
* stream:tcp
* stream:udp
* suricata
* symantec:ep:agent:file
* symantec:ep:agt_system:file
* symantec:ep:behavior:file
* symantec:ep:packet:file
* symantec:ep:scan:file
* symantec:ep:scm_system:file
* symantec:ep:security:file
* symantec:ep:traffic:file
* syslog
* time
* top
* unix:listeningports
* unix:service
* unix:update
* unix:uptime
* unix:useraccounts
* unix:version
* userswithloginprivs
* vmstat
* web_ping
* weblogic_access_combined
* weblogic_stdout
* who
* windowsupdatelog
* wineventlog:application
* wineventlog:directory-service
* wineventlog:security
* wineventlog:system
* winhostmon
* winregistry
* xmlwineventlog:microsoft-windows-sysmon/operational

`index=botsv2 earliest=0`

### References

- - [Boss of the SOC (BOTS)v2 Advanced APT Hunting Companion App for Splunk - SplunkBase](https://splunkbase.splunk.com/app/4430/)
- [Splunk BOTSv2 - Github](https://github.com/splunk/botsv2)
- [Boss of the SOC (BOTS) Advanced APT Hunting Companion App: Now Available on Splunkbase
](https://www.splunk.com/en_us/blog/security/boss-of-the-soc-bots-advanced-apt-hunting-companion-app-now-available-on-splunkbase.html)
- [Boss of the SOC 2.0 Dataset, Questions and Answers Open-Sourced and Ready for Download
](https://www.splunk.com/en_us/blog/security/boss-of-the-soc-2-0-dataset-questions-and-answers-open-sourced-and-ready-for-download.html)


## BOTSv3

### The Story


### Get it

| Dataset          | Description | Size | Format | MD5 |
| ---------------- | ----------- | ---- | ------ | --- |
| [BOTS V3 Dataset](https://botsdataset.s3.amazonaws.com/botsv3/botsv3_data_set.tgz) |  BOTSv3 dataset. | 320.1MB | Pre-indexed Splunk | a0757848cc207718279de50447da8eb2 |

### Install

[Easy install script](install_splunk_botsv3.sh)

One liner:

`wget -O - https://raw.githubusercontent.com/MHaggis/notes/master/Splunk%2BBOTS_build/install_splunk_botsv3.sh | bash`


### Whats included?
* access_combined
* alternatives
* amazon-ssm-agent
* amazon-ssm-agent-too_small
* apache_error
* aws:cloudtrail
* aws:cloudwatch
* aws:cloudwatch:guardduty
* aws:cloudwatchlogs
* aws:cloudwatchlogs:vpcflow
* aws:config:rule
* aws:description
* aws:elb:accesslogs
* aws:rds:audit
* aws:rds:error
* aws:s3:accesslogs
* bandwidth
* bash_history
* bootstrap
* cisco:asa
* cloud-init
* cloud-init-output
* code42:api
* code42:computer
* code42:org
* code42:security
* code42:user
* config_file
* cpu
* cron-too_small
* df
* dmesg
* dpkg
* error-too_small
* errors
* errors-too_small
* ess_content_importer
* hardware
* history-2
* interfaces
* iostat
* lastlog
* linux_audit
* linux_secure
* localhost-5
* lsof
* maillog-too_small
* ms:aad:audit
* ms:aad:signin
* ms:o365:management
* ms:o365:reporting:messagetrace
* netstat
* o365:management:activity
* openports
* osquery:info
* osquery:results
* osquery:warning
* out-3
* package
* perfmonmk:process
* protocol
* ps
* script:getendpointinfo
* script:installedapps
* script:listeningports
* stream:arp
* stream:dhcp
* stream:dns
* stream:http
* stream:icmp
* stream:igmp
* stream:ip
* stream:mysql
* stream:smb
* stream:smtp
* stream:tcp
* stream:udp
* symantec:ep:agent:file
* symantec:ep:agt_system:file
* symantec:ep:behavior:file
* symantec:ep:packet:file
* symantec:ep:risk:file
* symantec:ep:scm_system:file
* symantec:ep:security:file
* symantec:ep:traffic:file
* syslog
* time
* top
* unix:listeningports
* unix:service
* unix:sshdconfig
* unix:update
* unix:uptime
* unix:useraccounts
* unix:version
* userswithloginprivs
* vmstat
* who
* wineventlog
* winhostmon
* xmlwineventlog:microsoft-windows-sysmon/operational
* yum-too_small

`index=botsv3 earliest=0`


### References

- [Splunk BOTSv3 - Github](https://github.com/splunk/botsv3)
- [Boss of the SOC v3 Dataset Released!
](https://www.splunk.com/en_us/blog/security/botsv3-dataset-released.html)


