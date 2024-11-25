#Requires -RunAsAdministrator

# Function to log messages with timestamp
function Write-LogMessage {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

# Function to log errors
function Write-LogError {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $Message" -ForegroundColor Red
}

# Function to verify IIS installation with retry
function Test-IISInstallation {
    param(
        [int]$RetryCount = 3,
        [int]$RetryDelay = 5
    )
    
    for ($i = 1; $i -le $RetryCount; $i++) {
        Write-LogMessage "Verifying IIS installation (Attempt $i of $RetryCount)..."
        
        # Check Windows Feature status
        $iisFeature = Get-WindowsFeature -Name Web-Server
        if (-not $iisFeature.Installed) {
            Write-LogMessage "IIS feature not installed, installing now..."
            Install-WindowsFeature -Name Web-Server -IncludeManagementTools
            Start-Sleep -Seconds $RetryDelay
            continue
        }
        
        # Check service status
        $iisService = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
        if (-not $iisService) {
            Write-LogMessage "W3SVC service not found, waiting..."
            Start-Sleep -Seconds $RetryDelay
            continue
        }
        
        # Try to start the service
        try {
            if ($iisService.Status -ne 'Running') {
                Start-Service W3SVC -ErrorAction Stop
                Start-Sleep -Seconds 2
            }
            return $true
        } catch {
            Write-LogMessage "Could not start W3SVC service, retrying..."
            Start-Sleep -Seconds $RetryDelay
            continue
        }
    }
    
    Write-LogError "IIS installation verification failed after $RetryCount attempts"
    return $false
}

# Function to get all IP addresses
function Get-AllIPAddresses {
    $ips = Get-NetIPAddress -AddressFamily IPv4 | 
           Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } |
           Select-Object IPAddress
    return $ips
}

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-LogError "Please run this script as Administrator"
    exit 1
}

Write-LogMessage "Starting IIS installation and configuration..."

# Stop IIS if it's running
Write-LogMessage "Stopping IIS if running..."
Stop-Service -Name W3SVC -Force -ErrorAction SilentlyContinue

# Install IIS and necessary features
Write-LogMessage "Installing IIS and required features..."
try {
    $installResult = Install-WindowsFeature -Name Web-Server, `
        Web-Common-Http, `
        Web-Default-Doc, `
        Web-Dir-Browsing, `
        Web-Http-Errors, `
        Web-Static-Content, `
        Web-Http-Logging, `
        Web-Stat-Compression, `
        Web-Filtering, `
        Web-Mgmt-Console, `
        Web-Asp-Net45, `
        Web-ISAPI-Ext, `
        Web-ISAPI-Filter, `
        Web-Net-Ext45 -IncludeManagementTools
    
    if (-not $installResult.Success) {
        throw "Failed to install IIS features. Exit code: $($installResult.ExitCode)"
    }
    
    Write-LogMessage "IIS features installation completed. Verifying..."
    Start-Sleep -Seconds 5  # Give Windows time to initialize services
    
} catch {
    Write-LogError "Failed to install IIS features: $_"
    exit 1
}

# Verify IIS installation with retry
if (-not (Test-IISInstallation -RetryCount 3 -RetryDelay 5)) {
    Write-LogError "IIS installation verification failed. Please try the following:"
    Write-Host "1. Run 'sfc /scannow' to check system files"
    Write-Host "2. Check Windows Update for pending updates"
    Write-Host "3. Review Event Viewer for errors"
    Write-Host "4. Try rebooting and running the script again"
    exit 1
}

Write-LogMessage "IIS installation verified successfully"

# Get web shells directory from user
do {
    $webShellsPath = Read-Host "Enter the full path for your web shells directory (e.g., C:\webshells)"
    
    # Remove trailing backslash if present
    $webShellsPath = $webShellsPath.TrimEnd('\')
    
    if (-not (Test-Path $webShellsPath)) {
        $createDir = Read-Host "Directory doesn't exist. Create it? (Y/N)"
        if ($createDir -eq 'Y' -or $createDir -eq 'y') {
            try {
                New-Item -ItemType Directory -Path $webShellsPath -Force | Out-Null
                Write-LogMessage "Directory created successfully"
            } catch {
                Write-LogError "Failed to create directory: $_"
                continue
            }
        } else {
            Write-LogError "Valid directory path required"
            continue
        }
    }
    break
} while ($true)

# Create new IIS website
Write-LogMessage "Configuring IIS website..."
try {
    # Stop Default Web Site
    Write-LogMessage "Stopping Default Web Site..."
    Stop-IISSite -Name "Default Web Site" -Confirm:$false -ErrorAction SilentlyContinue
    
    # Create new application pool
    $poolName = "WebShellsPool"
    Write-LogMessage "Configuring application pool '$poolName'..."
    
    # Remove existing app pool if it exists
    if (Get-IISAppPool -Name $poolName -ErrorAction SilentlyContinue) {
        Write-LogMessage "Removing existing application pool..."
        Remove-WebAppPool -Name $poolName -ErrorAction SilentlyContinue
    }
    
    # Create new app pool
    Write-LogMessage "Creating new application pool..."
    New-WebAppPool -Name $poolName -Force
    
    # Configure app pool settings
    Write-LogMessage "Configuring application pool settings..."
    Set-ItemProperty "IIS:\AppPools\$poolName" -Name "managedRuntimeVersion" -Value "v4.0"
    Set-ItemProperty "IIS:\AppPools\$poolName" -Name "managedPipelineMode" -Value "Integrated"

    # Create new website
    $siteName = "WebShells"
    Write-LogMessage "Creating website '$siteName'..."
    
    # Remove existing website if it exists
    if (Get-Website -Name $siteName) {
        Write-LogMessage "Removing existing website..."
        Remove-Website -Name $siteName
    }
    
    # Create the new website
    Write-LogMessage "Creating new website..."
    $website = New-Website -Name $siteName `
                          -PhysicalPath $webShellsPath `
                          -ApplicationPool $poolName `
                          -Port 80 `
                          -Force
    
    if ($website) {
        Write-LogMessage "Website created successfully"
    } else {
        throw "Failed to create website"
    }

    # Configure website permissions
    Write-LogMessage "Setting directory permissions..."
    $acl = Get-Acl $webShellsPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "IIS_IUSRS", 
        "FullControl", 
        "ContainerInherit,ObjectInherit", 
        "None", 
        "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl $webShellsPath $acl
    
    # Enable directory browsing and other features
    Write-LogMessage "Configuring website features..."
    Set-WebConfigurationProperty -Filter /system.webServer/directoryBrowse `
                                -Name enabled `
                                -Value $true `
                                -PSPath "IIS:\Sites\$siteName"
    
    Set-WebConfigurationProperty -Filter /system.webServer/security/requestFiltering `
                                -Name allowDoubleEscaping `
                                -Value $true `
                                -PSPath "IIS:\Sites\$siteName"

    Write-LogMessage "IIS configuration completed successfully"
} catch {
    Write-LogError "Failed to configure IIS website: $_"
    Write-LogError "Stack Trace: $($_.ScriptStackTrace)"
    
    # Additional error information
    Write-LogMessage "Checking IIS components..."
    Write-LogMessage "Application Pool Status: $(Get-IISAppPool -Name $poolName -ErrorAction SilentlyContinue)"
    Write-LogMessage "Website Status: $(Get-Website -Name $siteName -ErrorAction SilentlyContinue)"
    Write-LogMessage "Directory Exists: $(Test-Path $webShellsPath)"
    
    exit 1
}

# Start IIS
Write-LogMessage "Starting IIS..."
try {
    Start-Service W3SVC
} catch {
    Write-LogError "Failed to start IIS: $_"
    exit 1
}

# Create test file
$testFile = Join-Path $webShellsPath "test.aspx"
@"
<%@ Page Language="C#" %>
<!DOCTYPE html>
<html>
<head><title>IIS Test</title></head>
<body>
<h1>IIS is working!</h1>
<p>Server Time: <%= DateTime.Now %></p>
</body>
</html>
"@ | Out-File -FilePath $testFile -Encoding UTF8

Write-LogMessage "Installation completed successfully!"

# Display connection information
Write-Host "`n=== IIS Service Status ===" -ForegroundColor Green
Get-Service W3SVC | Format-Table Name, Status, DisplayName

Write-Host "`n=== Connection Information ===" -ForegroundColor Green
Write-Host "Local URL: http://localhost/"

Write-Host "`nAvailable IP addresses to connect to:" -ForegroundColor Green
Get-AllIPAddresses | ForEach-Object {
    Write-Host "http://$($_.IPAddress)/"
}

Write-Host "`nPublic IP address:" -ForegroundColor Green
try {
    $publicIP = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -UseBasicParsing).Content
    Write-Host "http://$publicIP/"
} catch {
    Write-Host "Could not determine public IP address"
}

Write-Host "`n=== Important File Locations ===" -ForegroundColor Green
Write-Host "Web root directory: $webShellsPath"
Write-Host "IIS configuration: %SystemRoot%\System32\inetsrv\config\"
Write-Host "IIS logs: %SystemRoot%\System32\LogFiles\"

Write-Host "`n=== Files available in $webShellsPath ===" -ForegroundColor Green
Get-ChildItem $webShellsPath | Format-Table Name, Length, LastWriteTime

Write-Host "`n=== Verification Steps ===" -ForegroundColor Green
Write-Host "1. IIS Status: $((Get-Service W3SVC).Status)"
Write-Host "2. .NET Version: $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)"
Write-Host "3. Directory Permissions: "
Get-Acl $webShellsPath | Format-List

Write-LogMessage "Setup complete! You can now access your web shells through IIS." 