<#
.SYNOPSIS
    SQL Server Installation Script

.DESCRIPTION
    This script automates the installation of SQL Server with predefined configurations.
    It downloads the SQL Server installer, extracts the files, configures the installation,
    and installs SQL Server with a specified SA password.

.PARAMETER DownloadPath
    The path to save the SQL Server installer. (default: C:\SQLServer2022-DEV.exe)

.PARAMETER ExtractPath
    The path to extract the SQL Server installation files. (default: C:\SQL2022)

.PARAMETER ConfigPath
    The path to the SQL Server configuration file. (default: C:\SQL2022\ConfigurationFile.ini)

.PARAMETER SQLPassword
    The SQL Server SA account password. (default: ComplexPass123!)

.PARAMETER LogPath
    The path to store installation logs. (default: C:\SQL2022\InstallLogs)

.EXAMPLE
    # Basic usage with default parameters
    .\install-SQL.ps1

.NOTES
    File Name      : install-SQL.ps1
    Author         : The Haag
    Prerequisite   : PowerShell 5.1 or later
                    Internet connectivity
                    Administrative privileges

    WARNING: This script installs SQL Server with predefined configurations.
    Ensure the configurations meet your security requirements.
    Default credentials should be changed post-installation.

.LINK
    https://github.com/MHaggis/notes/tree/master/utilities/SQLSSTT
#>

$ErrorActionPreference = "Stop"

# Configuration
$config = @{
    DownloadPath = "C:\SQLServer2022-DEV.exe"
    ExtractPath = "C:\SQL2022"
    ConfigPath = "C:\SQL2022\ConfigurationFile.ini"
    SQLPassword = "ComplexPass123!"
    LogPath = "C:\SQL2022\InstallLogs"
}

function Initialize-Logging {
    try {
        if (-not (Test-Path $config.LogPath)) {
            New-Item -ItemType Directory -Force -Path $config.LogPath | Out-Null
        }
        $logFile = Join-Path $config.LogPath "install.log"
        if (-not (Test-Path $logFile)) {
            New-Item -ItemType File -Force -Path $logFile | Out-Null
        }
        return $true
    }
    catch {
        Write-Host "CRITICAL ERROR: Failed to initialize logging: $_"
        return $false
    }
}

function Write-Log {
    param($Message)
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] $Message"
        Write-Host $logMessage
        Add-Content -Path (Join-Path $config.LogPath "install.log") -Value $logMessage
    }
    catch {
        Write-Host "ERROR: Failed to write to log: $_"
        Write-Host $Message
    }
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Initialize-InstallationEnvironment {
    try {
        Write-Log "Creating installation directories..."
        New-Item -ItemType Directory -Force -Path $config.ExtractPath | Out-Null
        
        # Check for existing SQL installation
        if (Test-Path "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER") {
            Write-Log "WARNING: Existing SQL Server installation detected!"
            throw "SQL Server already installed. Please remove existing installation first."
        }

        # Check disk space (need at least 6GB free)
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -lt 6) {
            throw "Insufficient disk space. Need at least 6GB, found $freeSpaceGB GB"
        }

        Write-Log "Environment check passed. Free space: $freeSpaceGB GB"
    }
    catch {
        Write-Log "ERROR during environment setup: $_"
        throw
    }
}

function Get-SQLServerInstaller {
    try {
        Write-Log "Downloading SQL Server installer..."
        
        # Define the SQL Server download URL - using 2022 Developer Edition
        $downloadUrl = "https://go.microsoft.com/fwlink/?linkid=2215158"
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $webClient = New-Object System.Net.WebClient
        Write-Log "Starting download from Microsoft servers..."
        $webClient.DownloadFile($downloadUrl, $config.DownloadPath)
        
        if (Test-Path $config.DownloadPath) {
            $fileSize = (Get-Item $config.DownloadPath).Length / 1MB
            Write-Log "SQL Server installer downloaded successfully (Size: $([math]::Round($fileSize, 2)) MB)"
            
            # Verify the file is not too small (which would indicate a download error)
            if ($fileSize -lt 1) {
                throw "Downloaded file is too small, possible download error"
            }
            return $true
        } else {
            throw "Download completed but installer file not found"
        }
    }
    catch {
        Write-Log "ERROR downloading SQL Server installer: $_"
        throw
    }
    finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}

function New-ConfigurationFile {
    try {
        Write-Log "Creating SQL Server configuration file..."
        $configContent = @"
[OPTIONS]
; Installation options
ACTION="Install"
FEATURES=SQLENGINE,Conn
INSTANCENAME="MSSQLSERVER"
INSTANCEDIR="C:\Program Files\Microsoft SQL Server"
INSTALLSHAREDDIR="C:\Program Files\Microsoft SQL Server"
INSTALLSHAREDWOWDIR="C:\Program Files (x86)\Microsoft SQL Server"
SQLSVCACCOUNT="NT Service\MSSQLSERVER"
SQLSYSADMINACCOUNTS="BUILTIN\Administrators"
AGTSVCACCOUNT="NT Service\SQLSERVERAGENT"
SQLSVCINSTANTFILEINIT="True"
SQLTEMPDBFILECOUNT="2"
SQLTEMPDBFILESIZE="8"
SQLTEMPDBFILEGROWTH="64"
SQLTEMPDBLOGFILESIZE="8"
SQLTEMPDBLOGFILEGROWTH="64"
SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"
TCPENABLED="1"
NPENABLED="1"
BROWSERSVCSTARTUPTYPE="Automatic"
SAPWD="$($config.SQLPassword)"
SECURITYMODE="SQL"
IACCEPTSQLSERVERLICENSETERMS="True"
"@
        Set-Content -Path $config.ConfigPath -Value $configContent
        Write-Log "Configuration file created successfully"
        return $true
    }
    catch {
        Write-Log "ERROR creating configuration file: $_"
        throw
    }
}

function Install-SQLServer {
    try {
        Write-Log "Starting SQL Server installation..."
        
        Write-Log "Running SQL Server setup..."
        $process = Start-Process -FilePath $config.DownloadPath -ArgumentList "/Q", "/ACTION=Install", "/IACCEPTSQLSERVERLICENSETERMS", "/CONFIGURATIONFILE=`"$($config.ConfigPath)`"" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            throw "SQL Server installation failed with exit code: $($process.ExitCode)"
        }
        
        Write-Log "SQL Server installation completed"
        return $true
    }
    catch {
        Write-Log "ERROR during SQL Server installation: $_"
        throw
    }
}

function Install-SQLPowerShellModule {
    try {
        Write-Log "Installing SQL Server PowerShell module..."
        
        if (Get-Module -ListAvailable -Name SqlServer) {
            Write-Log "SQL Server PowerShell module already installed"
        } else {
            Write-Log "Installing SqlServer module from PowerShell Gallery..."
            Install-Module -Name SqlServer -Force -AllowClobber
        }
        
        return $true
    }
    catch {
        Write-Log "WARNING: Failed to install SQL Server PowerShell module: $_"
        Write-Log "This is non-critical and can be installed later"
        return $true
    }
}

function Test-SQLInstallation {
    try {
        Write-Log "Verifying SQL Server installation..."
        
        $attempts = 0
        $maxAttempts = 10
        
        while ($attempts -lt $maxAttempts) {
            $service = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                break
            }
            Write-Log "Waiting for SQL Server service to start..."
            Start-Sleep -Seconds 30
            $attempts++
        }
        
        if ($attempts -eq $maxAttempts) {
            throw "SQL Server service did not start in the expected time"
        }
        
        $connectionString = "Server=localhost;User ID=sa;Password=$($config.SQLPassword)"
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $connection.Open()
        $connection.Close()
        
        Write-Log "SQL Server installation verified successfully"
        return $true
    }
    catch {
        Write-Log "ERROR verifying SQL Server installation: $_"
        throw
    }
}

try {
    if (-not (Initialize-Logging)) {
        throw "Failed to initialize logging system"
    }

    Write-Log "Starting SQL Server installation process..."
    
    if (-not (Test-AdminPrivileges)) {
        throw "This script must be run as Administrator"
    }

    Initialize-InstallationEnvironment
    Get-SQLServerInstaller
    New-ConfigurationFile
    Install-SQLServer
    Install-SQLPowerShellModule
    
    if (Test-SQLInstallation) {
        Write-Log "Installation completed successfully!"
        Write-Log "Default instance: localhost"
        Write-Log "SA Password: $($config.SQLPassword)"
    }
    else {
        throw "Installation verification failed"
    }
}
catch {
    $errorMessage = $_.Exception.Message
    if (Test-Path (Join-Path $config.LogPath "install.log")) {
        Write-Log "CRITICAL ERROR: $errorMessage"
        Write-Log "Installation failed. Please check the logs at $($config.LogPath)\install.log"
    }
    else {
        Write-Host "CRITICAL ERROR: $errorMessage"
        Write-Host "Failed to write to log file. Installation failed."
    }
    exit 1
}