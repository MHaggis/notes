<#
.SYNOPSIS
    MandatoryProfilePersistence - Atomic Testing for NTUSER.MAN Registry Bypass
    
.DESCRIPTION
    A focused TUI for testing NTUSER.MAN mandatory profile persistence technique.
    This technique bypasses EDR registry callbacks by loading persistence keys
    directly from disk during user logon.
    
    Reference: https://deceptiq.com/blog/ntuser-man-registry-persistence
    
.NOTES
    Author: @Mhaggis
    Version: 1.0
#>

$Script:ToolVersion = "1.0"
$Script:TestResults = @()
$Script:ResultsFile = Join-Path $PSScriptRoot "mpp_results.json"
$Script:BackupPath = Join-Path $PSScriptRoot "backups"

if (Test-Path $Script:ResultsFile) {
    try {
        $Script:TestResults = Get-Content $Script:ResultsFile | ConvertFrom-Json
        $Script:TestResults = @($Script:TestResults)
    } catch {
        $Script:TestResults = @()
    }
}

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  MANDATORY PROFILE PERSISTENCE" -ForegroundColor Red
    Write-Host "  ==============================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  NTUSER.MAN Registry Callback Bypass Testing" -ForegroundColor Gray
    Write-Host "  Version $Script:ToolVersion" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ==========================================================" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-TechniqueInfo {
    Show-Banner
    Write-Host "  [TECHNIQUE OVERVIEW]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  The NTUSER.MAN Technique:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  EDR solutions monitor registry via CmRegisterCallbackEx kernel callbacks." -ForegroundColor Gray
    Write-Host "  When RegSetValue or RegCreateKey is called, EDR gets notified." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  BUT..." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Windows loads NTUSER.MAN (mandatory profile) INSTEAD of NTUSER.DAT when present." -ForegroundColor White
    Write-Host "  The hive is loaded directly from disk - NO registry API calls." -ForegroundColor White
    Write-Host "  Registry callbacks are NOT triggered. EDR is blind." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Normal Registry Write:" -ForegroundColor Yellow
    Write-Host "    Process -> RegSetValue -> Kernel Callback -> EDR SEES IT" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  NTUSER.MAN Technique:" -ForegroundColor Red
    Write-Host "    Write NTUSER.MAN -> User Logon -> Hive Loaded -> EDR IS BLIND" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Detection Opportunities:" -ForegroundColor Green
    Write-Host "    - File writes to NTUSER.MAN in any profile directory" -ForegroundColor Gray
    Write-Host "    - File writes to NTUSER.MAN on roaming profile shares" -ForegroundColor Gray
    Write-Host "    - Existence of .MAN files outside expected deployments" -ForegroundColor Gray
    Write-Host "    - Hive load events correlating with unexpected .MAN files" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Reference: https://deceptiq.com/blog/ntuser-man-registry-persistence" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-MainMenu {
    Show-Banner
    Write-Host "  [MAIN MENU]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    1 - Learn About This Technique" -ForegroundColor White
    Write-Host "    2 - Reconnaissance - Check for Existing NTUSER.MAN Files" -ForegroundColor White
    Write-Host "    3 - Export Current HKCU Hive (as .reg)" -ForegroundColor White
    Write-Host "    4 - Create Test NTUSER.MAN with Persistence Keys" -ForegroundColor White
    Write-Host "    5 - [ATOMIC] Full Attack Simulation" -ForegroundColor Red
    Write-Host "    6 - Cleanup / Remove Test Artifacts" -ForegroundColor White
    Write-Host "    7 - View Test Results" -ForegroundColor White
    Write-Host ""
    Write-Host "    Q - Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ==========================================================" -ForegroundColor DarkGray
    Write-Host ""
}

function Log-TestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Details,
        [string]$Technique = "NTUSER.MAN Persistence"
    )
    
    $result = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TestName = $TestName
        Technique = $Technique
        Status = $Status
        Details = $Details
    }
    
    $Script:TestResults += $result
    
    try {
        $Script:TestResults | ConvertTo-Json -Depth 10 | Out-File $Script:ResultsFile -Force
    } catch {
        # Silent fail
    }
}

function Invoke-Recon {
    Show-Banner
    Write-Host "  [RECONNAISSANCE]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [*] Scanning for existing NTUSER.MAN files..." -ForegroundColor Yellow
    Write-Host ""
    
    $usersPath = "$env:SystemDrive\Users"
    $foundFiles = @()
    
    try {
        $profiles = Get-ChildItem -Path $usersPath -Directory -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Name -notin @("Public", "Default", "Default User", "All Users") }
        
        foreach ($profile in $profiles) {
            $ntuserMan = Join-Path $profile.FullName "NTUSER.MAN"
            $ntuserDat = Join-Path $profile.FullName "NTUSER.DAT"
            
            Write-Host "  Checking: $($profile.Name)" -ForegroundColor Gray
            
            if (Test-Path $ntuserMan) {
                Write-Host "    [!] NTUSER.MAN FOUND!" -ForegroundColor Red
                $fileInfo = Get-Item $ntuserMan
                Write-Host "        Path: $ntuserMan" -ForegroundColor Yellow
                Write-Host "        Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
                Write-Host "        Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
                $foundFiles += $ntuserMan
            } else {
                Write-Host "    [+] No NTUSER.MAN (normal)" -ForegroundColor Green
            }
            
            if (Test-Path $ntuserDat) {
                $datInfo = Get-Item $ntuserDat -Force
                Write-Host "    [*] NTUSER.DAT: $($datInfo.Length) bytes" -ForegroundColor DarkGray
            }
            Write-Host ""
        }
        
        Write-Host "  ==========================================================" -ForegroundColor DarkGray
        Write-Host ""
        
        if ($foundFiles.Count -gt 0) {
            Write-Host "  [!] WARNING: Found $($foundFiles.Count) NTUSER.MAN file(s)!" -ForegroundColor Red
            Log-TestResult -TestName "Recon - NTUSER.MAN Scan" -Status "ALERT" -Details "Found $($foundFiles.Count) NTUSER.MAN files"
        } else {
            Write-Host "  [+] No NTUSER.MAN files found. Environment is clean." -ForegroundColor Green
            Log-TestResult -TestName "Recon - NTUSER.MAN Scan" -Status "SUCCESS" -Details "No NTUSER.MAN files found"
        }
    } catch {
        Write-Host "  [-] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Log-TestResult -TestName "Recon - NTUSER.MAN Scan" -Status "ERROR" -Details $_.Exception.Message
    }
    
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-HKCUHive {
    Show-Banner
    Write-Host "  [EXPORT HKCU HIVE]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [*] This will export your current HKCU registry hive to .reg format" -ForegroundColor Cyan
    Write-Host "  [*] Text format (.reg) does NOT require elevation" -ForegroundColor Gray
    Write-Host ""
    
    if (-not (Test-Path $Script:BackupPath)) {
        New-Item -ItemType Directory -Path $Script:BackupPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $exportPath = Join-Path $Script:BackupPath "HKCU_Export_$timestamp.reg"
    
    Write-Host "  Export path: $exportPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Continue? (Y/N): " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "  [-] Cancelled." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return
    }
    
    Write-Host ""
    Write-Host "  [*] Exporting HKCU hive..." -ForegroundColor Yellow
    
    try {
        $result = reg export HKCU $exportPath /y 2>&1
        
        if (Test-Path $exportPath) {
            $fileInfo = Get-Item $exportPath
            Write-Host "  [+] SUCCESS! Exported HKCU hive" -ForegroundColor Green
            Write-Host "  [*] File: $exportPath" -ForegroundColor Cyan
            Write-Host "  [*] Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
            Log-TestResult -TestName "Export HKCU Hive" -Status "SUCCESS" -Details "Exported to $exportPath"
        } else {
            Write-Host "  [-] Export failed - file not created" -ForegroundColor Red
            Log-TestResult -TestName "Export HKCU Hive" -Status "FAILED" -Details "File not created"
        }
    } catch {
        Write-Host "  [-] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Log-TestResult -TestName "Export HKCU Hive" -Status "ERROR" -Details $_.Exception.Message
    }
    
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Create-TestNTUserMan {
    Show-Banner
    Write-Host "  [CREATE TEST NTUSER.MAN]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [!] WARNING: This will create a test NTUSER.MAN in your profile!" -ForegroundColor Red
    Write-Host ""
    
    $currentUser = $env:USERNAME
    $profilePath = $env:USERPROFILE
    $ntuserMan = Join-Path $profilePath "NTUSER.MAN"
    
    Write-Host "  Target Profile: $profilePath" -ForegroundColor Cyan
    Write-Host "  Current User: $currentUser" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path $ntuserMan) {
        Write-Host "  [!] NTUSER.MAN already exists!" -ForegroundColor Red
        Write-Host "  [*] Remove it first using the cleanup option" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Press any key to return..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Write-Host "  This creates an NTUSER.MAN placeholder to trigger file detection" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Type CREATE to proceed: " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    
    if ($confirm -ne "CREATE") {
        Write-Host "  [-] Cancelled." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return
    }
    
    Write-Host ""
    Write-Host "  [*] Creating NTUSER.MAN marker file..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $markerContent = "NTUSER.MAN test marker created by MandatoryProfilePersistence atomic test at $timestamp"
    
    try {
        [System.IO.File]::WriteAllText($ntuserMan, $markerContent)
        
        if (Test-Path $ntuserMan) {
            Write-Host "  [+] SUCCESS! Created NTUSER.MAN marker file" -ForegroundColor Green
            Write-Host "  [*] Path: $ntuserMan" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  [!] CHECK YOUR EDR/SIEM NOW!" -ForegroundColor Red
            Write-Host "  [!] You should see a file write event to NTUSER.MAN" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  [*] This marker file is NOT a valid hive" -ForegroundColor Gray
            Write-Host "  [*] It will not load on logon (safe for testing)" -ForegroundColor Gray
            Write-Host "  [*] Use cleanup option to remove" -ForegroundColor Gray
            
            Log-TestResult -TestName "Create NTUSER.MAN Marker" -Status "SUCCESS" -Details "Created marker at $ntuserMan"
        }
    } catch {
        Write-Host "  [-] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [*] Try running as administrator" -ForegroundColor Yellow
        Log-TestResult -TestName "Create NTUSER.MAN Marker" -Status "ERROR" -Details $_.Exception.Message
    }
    
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-FullAtomicTest {
    Show-Banner
    Write-Host "  [FULL ATOMIC TEST]" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This test simulates the complete NTUSER.MAN attack chain:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Target Profile Path:" -ForegroundColor Cyan
    Write-Host "    $env:USERPROFILE" -ForegroundColor White
    Write-Host ""
    Write-Host "  File to Create:" -ForegroundColor Cyan
    Write-Host "    $env:USERPROFILE\NTUSER.MAN" -ForegroundColor White
    Write-Host ""
    Write-Host "  Simulated Persistence Keys (in marker file):" -ForegroundColor Cyan
    Write-Host "    HKCU\Software\Microsoft\Windows\CurrentVersion\Run" -ForegroundColor White
    Write-Host "      MPP_AtomicTest = calc.exe" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [!] NOTE: This creates a MARKER file, not a real hive." -ForegroundColor Yellow
    Write-Host "  [!] The marker will trigger file detection but not actually" -ForegroundColor Yellow
    Write-Host "  [!] execute persistence (safe for testing)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [!] YOUR EDR/SYSMON SHOULD DETECT:" -ForegroundColor Magenta
    Write-Host "      - Sysmon Event ID 11 (FileCreate)" -ForegroundColor Gray
    Write-Host "      - File: $env:USERPROFILE\NTUSER.MAN" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Type ATOMIC to proceed: " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    
    if ($confirm -ne "ATOMIC") {
        Write-Host "  [-] Cancelled." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $profilePath = $env:USERPROFILE
    $ntuserMan = Join-Path $profilePath "NTUSER.MAN"
    
    Write-Host ""
    Write-Host "  ==========================================================" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "  [STEP 1] Checking for existing NTUSER.MAN..." -ForegroundColor Cyan
    if (Test-Path $ntuserMan) {
        Write-Host "  [!] NTUSER.MAN already exists - aborting" -ForegroundColor Red
        Write-Host "  [*] Run cleanup first" -ForegroundColor Yellow
        Log-TestResult -TestName "Full Atomic Test" -Status "ABORTED" -Details "NTUSER.MAN already exists"
        Write-Host ""
        Write-Host "  Press any key to return..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    Write-Host "  [+] No existing NTUSER.MAN - proceeding" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  [STEP 2] Setting up backup directory..." -ForegroundColor Cyan
    if (-not (Test-Path $Script:BackupPath)) {
        New-Item -ItemType Directory -Path $Script:BackupPath -Force | Out-Null
    }
    Write-Host "  [+] Backup path: $Script:BackupPath" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "  [STEP 3] Creating NTUSER.MAN file..." -ForegroundColor Cyan
    Write-Host "  [*] Target: $ntuserMan" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $markerLines = @(
            "NTUSER.MAN ATOMIC TEST MARKER",
            "Created: $timestamp",
            "Tool: MandatoryProfilePersistence.ps1",
            "Purpose: EDR Detection Validation",
            "",
            "This is NOT a valid registry hive - it is a test marker.",
            "Your EDR should have detected this file write!"
        )
        $markerContent = $markerLines -join "`r`n"
        
        [System.IO.File]::WriteAllText($ntuserMan, $markerContent)
        
        if (Test-Path $ntuserMan) {
            $fileInfo = Get-Item $ntuserMan
            Write-Host "  [+] SUCCESS! NTUSER.MAN marker file created!" -ForegroundColor Green
            Write-Host ""
            Write-Host "  File Details:" -ForegroundColor Cyan
            Write-Host "    Path: $ntuserMan" -ForegroundColor Gray
            Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
            Write-Host "    Created: $($fileInfo.CreationTime)" -ForegroundColor Gray
            Write-Host ""
            
            Log-TestResult -TestName "Full Atomic Test" -Status "SUCCESS" -Details "Created NTUSER.MAN at $ntuserMan"
        }
    } catch {
        Write-Host "  [-] ERROR creating NTUSER.MAN: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "  [*] TIP: Try running PowerShell as Administrator" -ForegroundColor Yellow
        Log-TestResult -TestName "Full Atomic Test" -Status "ERROR" -Details $_.Exception.Message
        Write-Host ""
        Write-Host "  Press any key to return..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Write-Host ""
    Write-Host "  ==========================================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [!] VALIDATION CHECKLIST:" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Check your EDR/SIEM for these indicators:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    - File Creation Event" -ForegroundColor White
    Write-Host "      Process: powershell.exe" -ForegroundColor Gray
    Write-Host "      Target: $ntuserMan" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    - Sysmon Event ID 11 (FileCreate)" -ForegroundColor White
    Write-Host "      TargetFilename: *\NTUSER.MAN" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [!] DO NOT FORGET TO RUN CLEANUP WHEN DONE!" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-Cleanup {
    Show-Banner
    Write-Host "  [CLEANUP]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [*] This will remove test artifacts created by this tool" -ForegroundColor Cyan
    Write-Host ""
    
    $profilePath = $env:USERPROFILE
    $ntuserMan = Join-Path $profilePath "NTUSER.MAN"
    $testRegKey = "HKCU:\Software\MPP_AtomicTest"
    $testRunKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    
    $cleanupItems = @()
    
    if (Test-Path $ntuserMan) {
        $cleanupItems += [PSCustomObject]@{
            Type = "File"
            Path = $ntuserMan
            Description = "NTUSER.MAN test file"
        }
    }
    
    if (Test-Path $testRegKey) {
        $cleanupItems += [PSCustomObject]@{
            Type = "RegistryKey"
            Path = $testRegKey
            Description = "Test registry key"
        }
    }
    
    try {
        $runKeyValue = Get-ItemProperty -Path $testRunKey -Name "MPP_AtomicTest" -ErrorAction SilentlyContinue
        if ($runKeyValue) {
            $cleanupItems += [PSCustomObject]@{
                Type = "RegistryValue"
                Path = "$testRunKey\MPP_AtomicTest"
                Description = "Test Run key entry"
            }
        }
    } catch {}
    
    if ($cleanupItems.Count -eq 0) {
        Write-Host "  [+] No test artifacts found - environment is clean!" -ForegroundColor Green
        Log-TestResult -TestName "Cleanup Check" -Status "SUCCESS" -Details "No artifacts found"
        Write-Host ""
        Write-Host "  Press any key to return..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Write-Host "  Found $($cleanupItems.Count) artifact(s) to clean:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($item in $cleanupItems) {
        Write-Host "    [$($item.Type)] $($item.Description)" -ForegroundColor Cyan
        Write-Host "      Path: $($item.Path)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "  Type CLEANUP to remove all: " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    
    if ($confirm -ne "CLEANUP") {
        Write-Host "  [-] Cancelled." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return
    }
    
    Write-Host ""
    Write-Host "  [*] Removing artifacts..." -ForegroundColor Yellow
    Write-Host ""
    
    $errors = 0
    
    foreach ($item in $cleanupItems) {
        try {
            switch ($item.Type) {
                "File" {
                    Remove-Item -Path $item.Path -Force
                    Write-Host "  [+] Removed file: $($item.Path)" -ForegroundColor Green
                }
                "RegistryKey" {
                    Remove-Item -Path $item.Path -Recurse -Force
                    Write-Host "  [+] Removed registry key: $($item.Path)" -ForegroundColor Green
                }
                "RegistryValue" {
                    $keyPath = Split-Path $item.Path
                    $valueName = Split-Path $item.Path -Leaf
                    Remove-ItemProperty -Path $keyPath -Name $valueName -Force
                    Write-Host "  [+] Removed registry value: $($item.Path)" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "  [-] Failed to remove: $($item.Path)" -ForegroundColor Red
            Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
            $errors++
        }
    }
    
    Write-Host ""
    
    if ($errors -eq 0) {
        Write-Host "  [+] Cleanup complete! All artifacts removed." -ForegroundColor Green
        Log-TestResult -TestName "Cleanup" -Status "SUCCESS" -Details "Removed $($cleanupItems.Count) artifacts"
    } else {
        Write-Host "  [!] Cleanup completed with $errors error(s)" -ForegroundColor Yellow
        Log-TestResult -TestName "Cleanup" -Status "PARTIAL" -Details "Removed with $errors errors"
    }
    
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-TestResults {
    Show-Banner
    Write-Host "  [TEST RESULTS]" -ForegroundColor Yellow
    Write-Host ""
    
    if ($Script:TestResults.Count -eq 0) {
        Write-Host "    No tests have been run yet." -ForegroundColor DarkGray
    } else {
        Write-Host "  Total Tests: $($Script:TestResults.Count)" -ForegroundColor Cyan
        Write-Host "  Results file: $Script:ResultsFile" -ForegroundColor DarkGray
        Write-Host ""
        
        foreach ($result in $Script:TestResults | Select-Object -Last 15) {
            $statusColor = switch ($result.Status) {
                "SUCCESS" { "Green" }
                "FAILED" { "Red" }
                "ERROR" { "Red" }
                "ALERT" { "Yellow" }
                "INFO" { "Cyan" }
                "PARTIAL" { "Yellow" }
                "ABORTED" { "Magenta" }
                default { "Gray" }
            }
            Write-Host "  [$($result.Timestamp)] $($result.Status) - $($result.TestName)" -ForegroundColor $statusColor
            Write-Host "    Details: $($result.Details)" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Start-MandatoryProfilePersistence {
    $running = $true
    
    while ($running) {
        Show-MainMenu
        Write-Host "  Select option: " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        
        switch ($choice.ToUpper()) {
            "1" { Show-TechniqueInfo }
            "2" { Invoke-Recon }
            "3" { Export-HKCUHive }
            "4" { Create-TestNTUserMan }
            "5" { Invoke-FullAtomicTest }
            "6" { Invoke-Cleanup }
            "7" { Show-TestResults }
            "Q" {
                $running = $false
                Show-Banner
                Write-Host "  [*] Thank you for using MandatoryProfilePersistence!" -ForegroundColor Cyan
                Write-Host "  [*] Total tests run: $($Script:TestResults.Count)" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "  [!] Remember: Run cleanup if you created test artifacts!" -ForegroundColor Yellow
                Write-Host ""
            }
            default {
                Write-Host "  [-] Invalid option" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

Start-MandatoryProfilePersistence
