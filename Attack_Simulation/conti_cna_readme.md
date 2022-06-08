
More here https://gist.github.com/MHaggis/4814555da8ec61bd7971f33fbdc9c11e

## AV_Query
AV_Query command Scans the registry for installed antiviruses
## upload
An alternate version of the upload command.
Downloads a local file (first argument) to a remote host (second argument, optional).
How to use: __upload </ local / path / to / file> [/ remote / path / to / file] __.
Usage example: __beacon> upload implant.exe \\ DC1 ​​\ c $ \ windows \ temp \ implant.exe__.
## Blacklist
Bacon blacklist. Removes bacon if it is started on a computer where the username and computer name are in the blacklist.
__blacklist-add__ - add to blacklist
__blacklist-remove__ - remove from blacklist
__blacklist-show__ - show blacklist
## Credpocalypse
Tracks bacons and collects credentials
Usage in bacon:
    __begin_credpocalypse__ - track current bacon
__end_credpocalypse [all] __ - stop tracking current / all bacons
__credpocalypse_interval [time] __ - bacon polling interval 1m, 5m (default), 10m, 30m, 60m
Usage in console script or other script:
    __begin_credpocalypse__ - track all bacons
__end_credpocalypse [all] __ - stop tracking all bacons
__credpocalypse_interval [time] __ - bacon polling interval 1m, 5m (default), 10m, 30m, 60m
Right click on the bacon to open the Credpocalypse menu
## powershell2
An alternative version of the powershell command with increased operational security
## Simple Beacon console status bar
Shows the working directory, change the width of the last bacon spawn indicator in the lower right corner to a fixed width
Adds an option to the cd command to return to the previous directory.
Usage: __cd -__
## dcom_shellexecute
Lateral movement with DCOM (ShellExecute)
Usage: __dcom_shellexecute [target] [listener] __ - create new bacon on target via DCOM ShellExecute object
## DebugKit
Additional debugging tools in the DebugKit pop-up menu, console script and in bacon.
Commands to the console script:
__! beaconinfo__ - get information about bacons
__! loaded_powershell__ - show loaded powershell cmdlets for each bacon
__! c2_sample_server__ - show how responses from C2 server look like
__! c2_sample_client__ - show how client requests look like
__! who__ - show everyone who is connected to the team server
__! pwn3d_hosts__ - show a list of hostnames on which sessions were ever created
__! show_data_keys__ - show keys in the Cobalt Strike data model
__! query_data_key <key_name> __ - get values ​​by key from the Cobalt Strike data model
__! sync_all_downloads__ - syncs the downloaded files from the Cobalt Strike server to the specified folder and recursively recreates the file paths that the files had on the target hosts
Usage: __! Sync_all_downloads [/ path / on / client / machine / to / save / downloads / to] <IP address of host to download files for> __
Bacon Console Commands:
__! iscsadmin__ - check the current bacon via the -isadmin function
## csfm
Queries the database for known commands, displays helpful tips for the operator.
Syntax: __csfm [List] __ - listing all csfm options
Example: __search computer, tip ntlm__
## EDR
Remotely polls the system for EDR products
Syntax: __edr_query [hostname] [arch] __
## Color Coded Files Listing
The script colors the output of the ls command and allows you to track the downloaded files by highlighting them
## Forwarded_Ports
Monitors configured remote port forwarding on all bacons and makes it easy to remove them
Using 'rportfwd' quickly consumes the pool of available local ports from which outbound traffic is being redirected, and manually tracking them becomes tedious on lengthy projects. This script aims to fill this gap by collecting these commands and presenting them in a beautiful visualization panel.
## HighLight_Beacons
Highlights new beacons in green, inactive ones in red.
## LogVis
Advanced visualization of the beacon console output.
## MASS-DCSYNC
DCSync attack against a list of domain users.
The user list file must contain one user per line.

## MIMIKATZ_ADDONS
Performs a password change, which allows you to change the NTLM password for this account.
Uses the Mimikatz Change Password feature, which allows you to change the NTLM password for a given account without logging setpassword events.

** Usage: ** password_change [Username] [Known old hash or password] [New hash or password] [SERVER / DC / localhost]

## PING_ALIASES
1. alias ** qping ** sends a ping packet using the command line.
** Usage **: qping [target]. The ** target ** parameter is optional.
2.alias ** smbscan ** scans port 445.

## PORTSCAN_RESULTS
Menu item in the View section. At startup, a tab with the results of smbscan execution opens.

## PROCESSCOLOR
Highlighting process categories (antiviruses, explorer, browsers, current process) in the process manager