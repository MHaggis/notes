sc.exe stop Seewolf >> seewolf_UninstallLog.txt
sc.exe delete Seewolf >> seewolf_UninstallLog.txt
del C:\Windows\System32\Drivers\U-527.sys >> seewolf_UninstallLog.txt
driverquery -v >> seewolf_UninstallLog.txt
sc.exe query Seewolf >> seewolf_UninstallLog.txt
