<#
.SYNOPSIS
Scans drivers against loldrivers.io database

.DESCRIPTION
The Scan-Drivers function will download a drivers.json file from loldrivers.io
and use it to check for known vulnerabilities in drivers found in the 
specified directory. It will display a summary in the console and also 
display the details in a GridView or save to a CSV file based on the output parameter.

.PARAMETER DriverPath
The path to the directory where the drivers to be scanned are located. 
Default is C:\windows\system32\drivers

.PARAMETER FileFilter
The file type filter to apply when scanning for drivers. 
Default is *.sys

.PARAMETER Output
The output format. It can be either "GridView" or "CSV". 
Default is "GridView"

.PARAMETER OutputPath
The path where to save the output CSV file. 
This parameter is used only when -Output "CSV" is selected.

.EXAMPLE
Scan-Drivers -DriverPath "C:\CustomPath" -FileFilter "*.sys" -Output "CSV" -OutputPath "C:\output"
#>
function Scan-Drivers {
    Param (
        [Parameter(Mandatory=$false,
                   HelpMessage="Path to the directory with drivers to be scanned")]
        [string]$DriverPath = "C:\windows\system32\drivers",

        [Parameter(Mandatory=$false,
                   HelpMessage="File type filter for driver files")]
        [string]$FileFilter = "*.sys",

        [Parameter(Mandatory=$false,
                   HelpMessage="Output format: GridView or CSV")]
        [ValidateSet("GridView", "CSV")]
        [string]$Output = "GridView",

        [Parameter(Mandatory=$false,
                   HelpMessage="Output path for CSV file. Used when -Output is set to 'CSV'.")]
        [string]$OutputPath = $PWD
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


# Display results in the console with color highlighting

Write-Output ""
$hashesSorted = $hashes | Sort-Object -Property @{Expression = { if ($_.Status -eq "Vulnerable") { 0 } elseif ($_.Status -eq "Error") { 1 } else { 2 } } }

# Check if output directory exists, create it if not
if (!(Test-Path -Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

# Check the selected output format
if ($Output -eq "GridView") {
    # Display the sorted results in Out-GridView
    $hashesSorted | Out-GridView -Title "Results from LOLDrivers scan, check Status column for value: Vulnerable"
} else {
    # Save the results to a CSV file
    $csvFileName = Join-Path -Path $OutputPath -ChildPath "LOLDrivers_Scan_Results.csv"
    $hashesSorted | Export-Csv -Path $csvFileName -NoTypeInformation

    Write-Host "The scan results have been saved to $csvFileName" -ForegroundColor Green
}

Write-Host "Scanning after LOLDrivers completed" -ForegroundColor Green
Write-Host "Found $vulnerableCount Vulnerable Drivers" -ForegroundColor $(if ($vulnerableCount -gt 0) { "Red" } else { "Green" })

}
