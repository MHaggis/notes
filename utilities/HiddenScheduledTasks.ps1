# Inspired by: https://www.binarydefense.com/resources/blog/diving-into-hidden-scheduled-tasks/
# Written by The Haag with Love

$asciiart = @"

#     #                                   #####                                                             #######                      
#     # # #####  #####  ###### #    #    #     #  ####  #    # ###### #####  #    # #      ###### #####        #      ##    ####  #    # 
#     # # #    # #    # #      ##   #    #       #    # #    # #      #    # #    # #      #      #    #       #     #  #  #      #   #  
####### # #    # #    # #####  # #  #     #####  #      ###### #####  #    # #    # #      #####  #    #       #    #    #  ####  ####   
#     # # #    # #    # #      #  # #          # #      #    # #      #    # #    # #      #      #    #       #    ######      # #  #   
#     # # #    # #    # #      #   ##    #     # #    # #    # #      #    # #    # #      #      #    #       #    #    # #    # #   #  
#     # # #####  #####  ###### #    #     #####   ####  #    # ###### #####   ####  ###### ###### #####        #    #    #  ####  #    # 
                                                                                                                                         
"@



Write-Host "Starting the Scheduled Task Atomic Tests" -ForegroundColor Cyan
Write-Host $asciiart -ForegroundColor Magenta

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Please run this script as an Administrator!" -ForegroundColor Red
    Exit
}

$testRegistryPath = "HKLM:\SOFTWARE\TestScheduledTaskRegistry"
If (-Not (Test-Path $testRegistryPath)) {
    New-Item -Path $testRegistryPath -Force | Out-Null
    Write-Host "Created test registry path for safe operations." -ForegroundColor Green
}

$taskName = "TestTask"
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Existing task removed." -ForegroundColor Yellow
}

Write-Host "Creating a base scheduled task..." -ForegroundColor Cyan
$action = New-ScheduledTaskAction -Execute 'notepad.exe'
$trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description "This is a test task for Atomic Red Team tests."

$taskPath = "$testRegistryPath\TestTask"
If (-Not (Test-Path $taskPath)) {
    New-Item -Path $taskPath -Force | Out-Null
}
New-ItemProperty -Path $taskPath -Name "SD" -Value "InitialSD" -PropertyType String -Force | Out-Null
Write-Host "Registry test environment set up successfully. Using path: $taskPath" -ForegroundColor Green

Function ModifyRegistry($path, $name, $value, $action) {
    Try {
        If ($action -eq "set") {
            Set-ItemProperty -Path $path -Name $name -Value $value
        } ElseIf ($action -eq "remove") {
            Remove-ItemProperty -Path $path -Name $name
        }
        Write-Host "Operation on SD value at ${path} succeeded." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to $action the SD value at ${path}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 1: Creation with Removed SD Value
Write-Host "Test 1: Creating a task with removed SD value at $taskPath..." -ForegroundColor Cyan
ModifyRegistry $taskPath "SD" $null "set"

# Test 2: Populate SD with fake data
Write-Host "Test 2: Populating SD value with fake binary data at $taskPath..." -ForegroundColor Cyan
$fakeSD = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("FakeSDData"))
ModifyRegistry $taskPath "SD" $fakeSD "set"

# Test 3: Deleting the SD value
Write-Host "Test 3: Deleting the SD value at $taskPath..." -ForegroundColor Cyan
ModifyRegistry $taskPath "SD" $null "remove"

# Test 4: Enumerate Tasks with Missing SD Values
Write-Host "Test 4: Enumerating tasks with missing SD values at $taskPath..." -ForegroundColor Cyan
$missingSDTasks = Get-ChildItem -Path $taskPath | Where-Object { -Not $_.GetValue("SD") }
$missingSDTasks | ForEach-Object { Write-Host "Task with missing SD at ${taskPath}: $($_.Name)" -ForegroundColor Green }

# Test 5: Set Deny Access SDDL
Write-Host "Test 5: Setting Deny Access SDDL at $taskPath..." -ForegroundColor Cyan
$denySDDL = "D:P(A;;GA;;;SY)(A;;GA;;;BA)"
ModifyRegistry $taskPath "SD" $denySDDL "set"

# Test 6: Sysmon Custom Rule Test
Write-Host "Test 6: Simulating SD value removal for Sysmon detection at $taskPath..." -ForegroundColor Cyan
ModifyRegistry $taskPath "SD" $null "remove"

# Test 7: Importing and executing task without creation logs
Write-Host "Test 7: Importing and executing task without creation logs..." -ForegroundColor Cyan
Start-ScheduledTask -TaskName $taskName
Write-Host "Task executed. Check for alerts on task execution without corresponding creation logs." -ForegroundColor Green

Write-Host "All tests completed!" -ForegroundColor Yellow
