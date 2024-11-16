<#
.SYNOPSIS
    Tests file creation and execution permissions across various Windows directories.

.DESCRIPTION
    This script attempts to create and execute different types of files in specified user and system paths
    to verify security boundaries and access controls.

.PARAMETER Verbose
    Enables verbose logging of script execution.

.PARAMETER ConfigPath
    Specifies the path to the configuration file in JSON format.

.PARAMETER Interactive
    Enables interactive mode where the user can choose which paths and file types to test.

.PARAMETER Force
    Forces the script to run without interactive mode.

.EXAMPLE
    .\ScriptHostTest.ps1 -Verbose -ConfigPath "C:\Configs\ScriptHostTestConfig.json"

.NOTES
    Author: The Haag
    Version: 1.1
#>

param (
    [switch]$VerboseLogging,
    [string]$ConfigPath = "ScriptHostTestConfig.json",
    [switch]$Interactive,
    [switch]$Force
)

$asciiArt = @"
 #####                               #     #                     #######                     
#     #  ####  #####  # #####  ##### #     #  ####   ####  #####    #    ######  ####  ##### 
#       #    # #    # # #    #   #   #     # #    # #        #      #    #      #        #   
 #####  #      #    # # #    #   #   ####### #    #  ####    #      #    #####   ####    #   
      # #      #####  # #####    #   #     # #    #      #   #      #    #           #   #   
#     # #    # #   #  # #        #   #     # #    # #    #   #      #    #      #    #   #   
 #####   ####  #    # # #        #   #     #  ####   ####    #      #    ######  ####    #   
                                                                                                 
   Security Testing & Validation Framework
"@

Write-Host $asciiArt -ForegroundColor Cyan
Write-Host "`n"

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    if ($Level -eq "INFO" -and -not $VerboseLogging) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] - $Message"
    Add-Content -Path "ScriptHostTest.log" -Value $logMessage

    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Green }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
    }
}

function Write-Summary {
    Write-Host "`n" 
    $headerFooter = "=" * 40
    Write-Host $headerFooter -ForegroundColor Cyan
    Write-Host "           TEST EXECUTION SUMMARY" -ForegroundColor Cyan
    Write-Host $headerFooter -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Tests Run    : " -NoNewline -ForegroundColor White
    Write-Host $results.Total -ForegroundColor Cyan
    Write-Host "Successful Tests   : " -NoNewline -ForegroundColor White
    Write-Host $results.Success -ForegroundColor Green
    Write-Host "Failed Tests       : " -NoNewline -ForegroundColor White
    Write-Host $results.Failed -ForegroundColor Red
    
    $successRate = if ($results.Total -gt 0) {
        [math]::Round(($results.Success / $results.Total) * 100, 2)
    } else {
        0
    }
    
    Write-Host "Success Rate       : " -NoNewline -ForegroundColor White
    Write-Host "$successRate%" -ForegroundColor $(if ($successRate -ge 80) { 'Green' } elseif ($successRate -ge 50) { 'Yellow' } else { 'Red' })
    Write-Host $headerFooter -ForegroundColor Cyan
    Write-Host ""
}

function Cleanup-TestFiles {
    Write-Log "Performing final cleanup..." -Level "INFO"
    $remainingFiles = @()
    while ($global:CreatedFiles.TryTake([ref]$remainingFiles)) {
        if (Test-Path $remainingFiles) {
            try {
                Remove-Item $remainingFiles -Force -ErrorAction Stop
                Write-Log "Cleaned up remaining file: $remainingFiles" -Level "INFO"
            }
            catch {
                Write-Log "Failed to clean up file: $remainingFiles - $_" -Level "ERROR"
            }
        }
    }
}

function Create-And-Run-File {
    param (
        [string]$path,
        [string]$extension,
        [string]$content,
        [string]$executor = $null
    )

    $script:results.Total++ 
    $fullPath = $null
    
    try {

        if (-not (Test-Path $path)) { throw "Path does not exist: $path" }

        $fileName = "test_$(Get-Random)$extension"
        $fullPath = Join-Path -Path $path -ChildPath $fileName

        [System.IO.File]::WriteAllText($fullPath, $content, [System.Text.UTF8Encoding]::new($false))
        $global:CreatedFiles.Add($fullPath)
        Write-Log "File created successfully: $fullPath" -Level "INFO"
       
        switch ($extension) {
            '.ps1' {
                $output = & $fullPath
                Write-Host $output
            }
            { $_ -in '.bat', '.cmd' } {
                $processStart = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$fullPath`"" -Wait -PassThru -NoNewWindow
                if ($processStart.ExitCode -ne 0) {
                    throw "Process exited with code: $($processStart.ExitCode)"
                }
            }
            { $_ -in '.vbs', '.vbe', '.js', '.jse' } {
                $processStart = Start-Process -FilePath "cscript.exe" -ArgumentList "//NoLogo `"$fullPath`"" -Wait -PassThru -NoNewWindow
                if ($processStart.ExitCode -ne 0) {
                    throw "Process exited with code: $($processStart.ExitCode)"
                }
            }
            { $_ -eq '.hta' } {
                $processStart = Start-Process -FilePath "mshta.exe" -ArgumentList "`"$fullPath`"" -Wait -PassThru -NoNewWindow
                if ($processStart.ExitCode -ne 0) {
                    throw "Process exited with code: $($processStart.ExitCode)"
                }
            }
            default {
                if ($executor) {
                    $processStart = Start-Process -FilePath $executor -ArgumentList "`"$fullPath`"" -Wait -PassThru -NoNewWindow
                    if ($processStart.ExitCode -ne 0) {
                        throw "Process exited with code: $($processStart.ExitCode)"
                    }
                } else {
                    throw "No executor specified for extension: $extension"
                }
            }
        }
        
        $script:results.Success++
        Write-Log "File executed successfully" -Level "INFO"
    }
    catch {
        $script:results.Failed++
        Write-Log "Error: $_" -Level "ERROR"
        throw  
    }
    finally {
        if ($fullPath -and (Test-Path $fullPath)) {
            Remove-Item $fullPath -Force -ErrorAction SilentlyContinue
            $global:CreatedFiles.TryTake([ref]$fullPath)
            Write-Log "Test file removed: $fullPath" -Level "INFO"
        }
    }

    $script:results.Total = $script:results.Success + $script:results.Failed
    return $script:results
}

$ScriptVersion = "1.1.0"
$global:CreatedFiles = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

$script:results = @{
    Total = 0
    Success = 0
    Failed = 0
}

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$contentStrings = @{
    PS1 = @"
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show('Hello from PowerShell!', 'PowerShell Script')
Write-Host "PowerShell script executed successfully"
"@
    
    BAT = @"
@echo off
echo Batch script executed successfully
mshta javascript:alert("Hello from Batch!");close();
"@
    
    VBS = @"
WScript.Echo "VBScript executed successfully"
MsgBox "Hello from VBScript!", 0, "VBScript"
"@
    
    JS = @"
WScript.Echo("JScript executed successfully");
var shell = new ActiveXObject("WScript.Shell");
shell.Popup("Hello from JScript!", 0, "JScript", 0);
"@
    
    HTA = @"
<html><head><title>HTA Test</title>
<hta:application id="htaTest" applicationname="HTATest" border="thin" borderstyle="normal" caption="yes"/>
<script language="VBScript">
Sub Window_OnLoad
    MsgBox "Hello from HTA!", 0, "HTA Test"
    window.close
End Sub
</script></head><body>HTA Test</body></html>
"@
}

$fileTypes = @(
    @{Ext = ".ps1"; Content = $contentStrings.PS1},
    @{Ext = ".bat"; Content = $contentStrings.BAT},
    @{Ext = ".cmd"; Content = $contentStrings.BAT},
    @{Ext = ".vbs"; Content = $contentStrings.VBS},
    @{Ext = ".js"; Content = $contentStrings.JS},
    @{Ext = ".jse"; Content = $contentStrings.JS; Executor = "cscript.exe"},
    @{Ext = ".hta"; Content = $contentStrings.HTA; Executor = "mshta.exe"}
)

trap {
    Write-Log "Script interrupted. Performing cleanup..." -Level "WARNING"
    foreach ($file in $global:CreatedFiles) {
        if (Test-Path $file) {
            try {
                Remove-Item $file -Force -ErrorAction Stop
                Write-Log "Cleaned up test file: $file" -Level "INFO"
            }
            catch {
                Write-Log "Failed to clean up file: $file - $_" -Level "ERROR"
            }
        }
    }
    Write-Summary
    exit
}

if (Test-Path $ConfigPath) {
    Write-Log "Loading configuration from $ConfigPath" -Level "INFO"
    $config = Get-Content -Path $ConfigPath | ConvertFrom-Json
    $userPaths = $config.UserPaths | ForEach-Object { 
        $expandedPath = $_.Replace("%USERNAME%", $env:USERNAME)
        if (Test-Path $expandedPath) {
            $expandedPath
        } else {
            Write-Log "Warning: Path does not exist: $expandedPath" -Level "WARNING"
        }
    } | Where-Object { $_ }  
    $systemPaths = $config.SystemPaths | Where-Object { Test-Path $_ }
} else {
    Write-Log "No configuration file found, using default paths" -Level "INFO"
    $userPaths = @(
        [System.Environment]::GetFolderPath("UserProfile") + "\Downloads",
        [System.Environment]::GetFolderPath("MyDocuments")
    ) | Where-Object { Test-Path $_ }
    
    $systemPaths = @(
        "$env:windir\Tasks",
        "$env:windir\tracing", 
        "$env:windir\registration\crmlog",
        "$env:windir\System32\Tasks",
        "$env:windir\System32\spool\drivers\color"
    ) | Where-Object { Test-Path $_ }
}

if ($Interactive -and -not $Force) {
    Write-Host "`nAvailable Test Paths:" -ForegroundColor Cyan
    Write-Host "`nUser Paths:"
    $userPaths | ForEach-Object { Write-Host "  - $_" }
    Write-Host "`nSystem Paths:"
    $systemPaths | ForEach-Object { Write-Host "  - $_" }
    
    $userChoice = Read-Host "`nDo you want to proceed with user path tests? (Y/N)"
    if ($userChoice -ne 'Y') { $userPaths = @() }
    
    $sysChoice = Read-Host "Do you want to proceed with system path tests? (Y/N)"
    if ($sysChoice -ne 'Y') { $systemPaths = @() }
    
    Write-Host "`nAvailable File Types:" -ForegroundColor Cyan
    $fileTypes | ForEach-Object { Write-Host "  - $($_.Ext)" }
    $typeChoice = Read-Host "`nDo you want to test all file types? (Y/N)"
    if ($typeChoice -ne 'Y') {
        $selectedTypes = Read-Host "Enter file extensions to test (comma-separated, e.g., .ps1,.bat)"
        $allowedTypes = $selectedTypes.Split(',').Trim()
        $fileTypes = $fileTypes | Where-Object { $_.Ext -in $allowedTypes }
    }
}

Write-Log "Starting script execution..." -Level "INFO"

Write-Log "Testing user paths..." -Level "INFO"
foreach ($path in $userPaths) {
    Write-Log "Testing user path: $path" -Level "INFO"
    foreach ($fileType in $fileTypes) {
        Write-Log "Testing file type: $($fileType.Ext)" -Level "INFO"
        Create-And-Run-File -path $path -extension $fileType.Ext -content $fileType.Content -executor $fileType.Executor
    }
}

Write-Log "Testing system paths (requires admin privileges)..." -Level "INFO"
foreach ($path in $systemPaths) {
    Write-Log "Testing system path: $path" -Level "INFO"
    foreach ($fileType in $fileTypes) {
        Write-Log "Testing file type: $($fileType.Ext)" -Level "INFO"
        Create-And-Run-File -path $path -extension $fileType.Ext -content $fileType.Content -executor $fileType.Executor
    }
}

Write-Log "`n============= Test Summary =============" -Level "INFO"
Write-Log "Total Tests Run: $($results.Total)" -Level "INFO"
Write-Log "Successful Tests: $($results.Success)" -Level "INFO"
Write-Log "Failed Tests: $($results.Failed)" -Level "ERROR"
Write-Log "Success Rate: $([math]::Round(($results.Success/$results.Total) * 100, 2))%" -Level "INFO"
Write-Log "=======================================" -Level "INFO"

Write-Summary

Cleanup-TestFiles
Write-Log "Script execution completed." -Level "INFO"