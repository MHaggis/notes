REM Wolfpack https://uboat.net/ops/wolfpacks/99.html

REM Move driver
copy U-527.sys C:\Windows\System32\drivers

sc.exe create Seewolf binpath=  "C:\Windows\System32\drivers\U-527.sys" type= kernel start= auto displayname= "Seewolf" >> seewolf_Install.log

REM Start Driver 
sc.exe start Seewolf >> seewolf_Install.log

REM Verify Installation

sc.exe query Seewolf >>  seewolf_Install.log
driverquery.exe | findstr Seewolf >> seewolf_Install.log