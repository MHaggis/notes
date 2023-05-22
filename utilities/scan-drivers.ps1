<#
.SYNOPSIS
Scans drivers against loldrivers.io database

.DESCRIPTION
The Scan-Drivers function will download a drivers.json file from loldrivers.io
and use it to check for known vulnerabilities in drivers found in the 
specified directory. It will display a summary in the console and also 
display the details in a GridView.
Inspired by https://github.com/Ekitji/Files/blob/main/LOLDriverScanner.ps1

.PARAMETER DriverPath
The path to the directory where the drivers to be scanned are located. 
Default is C:\windows\system32\drivers

.PARAMETER FileFilter
The file type filter to apply when scanning for drivers. 
Default is *.sys

.EXAMPLE
Scan-Drivers -DriverPath "C:\CustomPath" -FileFilter "*.sys"
#>
function Scan-Drivers {
    Param (
        [Parameter(Mandatory=$false,
                   HelpMessage="Path to the directory with drivers to be scanned")]
        [string]$DriverPath = "C:\windows\system32\drivers",

        [Parameter(Mandatory=$false,
                   HelpMessage="File type filter for driver files")]
        [string]$FileFilter = "*.sys"
    )

    # Specify the URL to the loldrivers.json file
    $loldriversUrl = "https://www.loldrivers.io/api/drivers.json"

    # Specify the path to the loldrivers.json file in AppData directory
    $loldriversFilePath = "$env:APPDATA\loldrivers\drivers.json"

    # Make sure the destination directory exists
    if (!(Test-Path -Path "$env:APPDATA\loldrivers")) {
        New-Item -ItemType Directory -Path "$env:APPDATA\loldrivers" -Force
    }

    # Download the loldrivers.json file only if it does not exist
    if (!(Test-Path -Path $loldriversFilePath)) {
        Invoke-WebRequest -Uri $loldriversUrl -OutFile $loldriversFilePath
    }

    # Get all driver files in user specified directory, default to C:\windows\system32\drivers
    $drivers = Get-ChildItem -Path $DriverPath -Force -Recurse -File -Filter $FileFilter

    # Read the contents of the loldrivers.json file
    $loldrivers = Get-Content -Path $loldriversFilePath | ConvertFrom-Json

    Write-Host "Checking $($drivers.Count) drivers in $DriverPath against loldrivers.io JSON file" -ForegroundColor Yellow

    #Declare a variable to keep track of the vulnerable drivers count
    $vulnerableCount = 0

$hashes = @()

foreach ($driver in $drivers) {
    try {
        # Calculate the SHA256 hash of the driver file
        $hash = Get-FileHash -Algorithm SHA256 -Path $driver.FullName -ErrorAction Stop | Select-Object -ExpandProperty Hash
        $status = "OK"
        $vulnerableSample = $loldrivers.KnownVulnerableSamples | Where-Object { $_.SHA256 -eq $hash }
       if ($vulnerableSample) {
        $status = "Vulnerable"
        $vulnerableCount++
        }
        # Calculate the Authenticode SHA256 hash of the driver file
        $authenticodeHash = (Get-AppLockerFileInformation -Path $driver.FullName).Hash
        $authenticodeHash = $authenticodeHash -replace 'SHA256 0X', ''
        
        # Check the Authenticode SHA256 hash against the drivers.json file
        $authenticodeMatch = $loldrivers.KnownVulnerableSamples.Authentihash| Where-Object { $_.SHA256 -eq $authenticodeHash} 

        if ($authenticodeMatch) {
        $status = "Vulnerable"
         if ($vulnerableSample -eq $null) {
                $vulnerableCount++
        }
        }
        $hashes += [PSCustomObject]@{
            Driver = $driver.Name
            SHA256Hash = $hash
            AuthenticodeHash = $authenticodeHash
            Status = $status
            Path = $driver.FullName
        }
    } catch {
        $hashes += [PSCustomObject]@{
            Driver = $driver.Name
            SHA256Hash = "Hash Calculation Failed: $($_.Exception.Message)"
            AuthenticodeHash = "Hash Calculation Failed: $($_.Exception.Message)"
            Status = "Error"
            Path = $driver.FullName
        }
    }
}

# Display results in the console with color highlighting
Write-Output ""
foreach ($hashEntry in $hashes) {
    $driver = $hashEntry.Driver
    $hash = $hashEntry.SHA256Hash
    $authenticodeHash = $hashEntry.AuthenticodeHash
    $status = $hashEntry.Status

    if ($status -eq "Vulnerable") {
        Write-Host "Driver: $driver"
        Write-Host "SHA256Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Red
    } elseif ($status -eq "Error") {
        Write-Host "Driver: $driver"
        Write-Host "SHA256Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Yellow
    } else {
        Write-Host "Driver: $driver"
        Write-Host "SHA256Hash:   $hash   AuthenticodeHash:   $authenticodeHash   Status: $status" -ForegroundColor Green
    }

    Write-Output ""
}

# Sort the array based on the "Status" column to display vulnerable drivers at the top in Out-GridView
Write-Output ""
$hashesSorted = $hashes | Sort-Object -Property @{Expression = { if ($_.Status -eq "Vulnerable") { 0 } elseif ($_.Status -eq "Error") { 1 } else { 2 } } }


# Display the sorted results in Out-GridView
$hashesSorted | Out-GridView -Title "Results from LOLDrivers scan, check Status column for value: Vulnerable"

Write-Host "Scanning after LOLDrivers completed" -ForegroundColor Green
Write-Host "Found $vulnerableCount Vulnerable Drivers" -ForegroundColor $(if ($vulnerableCount -gt 0) { "Red" } else { "Green" })
}