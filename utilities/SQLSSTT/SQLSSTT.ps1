<#
.SYNOPSIS
    SQL Server Security Testing Tool (SQLSSTT)

.DESCRIPTION
    A comprehensive SQL Server security testing tool that checks for common misconfigurations,
    vulnerabilities, and potential attack vectors using both Invoke-Sqlcmd and sqlcmd.exe methods.

.PARAMETER Server
    The SQL Server instance to test (default: localhost)

.PARAMETER Database
    The database to connect to (default: master)

.PARAMETER Username
    SQL Server authentication username (default: sa)

.PARAMETER Password
    SQL Server authentication password (default: ComplexPass123!)

.PARAMETER UseBothMethods
    Switch to enable testing with both Invoke-Sqlcmd and sqlcmd.exe (default: true)

.EXAMPLE
    # Basic usage with default parameters
    .\SQLSSTT.ps1

.EXAMPLE
    # Test a remote SQL Server
    .\SQLSSTT.ps1 -Server "sql.contoso.com" -Username "pentester" -Password "SecurePass123!"

.EXAMPLE
    # Test specific database with single method
    .\SQLSSTT.ps1 -Server "dbserver" -Database "target_db" -UseBothMethods:$false

.NOTES
    File Name      : SQLSSTT.ps1
    Author         : The Haag
    Prerequisite   : PowerShell 5.1 or later
                    SQL Server PowerShell Module (for Invoke-Sqlcmd)
                    SQL Server Command Line Utilities (for sqlcmd.exe)
    
    WARNING: This tool is for authorized security testing only. 
    Improper use could cause system instability or security issues.

.LINK
    https://github.com/MHaggis/notes/tree/master/utilities/SQLSSTT
#>

[CmdletBinding()]
param (
    [string]$Server = "localhost",
    [string]$Database = "master",
    [string]$Username = "sa", 
    [string]$Password = "ComplexPass123!",
    [switch]$UseBothMethods = $true
)


$banner = @"
 ____   ___  _     ____ ____ _____ _____ 
/ ___| / _ \| |   / ___/ ___|_   _|_   _|
\___ \| | | | |   \___ \___ \ | |   | |  
 ___) | |_| | |___ ___) |__) || |   | |  
|____/ \__\_\_____|____/____/ |_|   |_|  
                                             
     SQL Server Security Testing Toolkit
"@

Write-Host $banner -ForegroundColor Cyan
Write-Host "`nStarting SQL Server security assessment...`n" -ForegroundColor Yellow

# Initialize settings
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Run-SqlCommand {
    param([string]$Command)
    try {
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Command))
        $result = Start-Process powershell.exe -ArgumentList "-EncodedCommand $encoded" -Wait -NoNewWindow -PassThru
        return $result.ExitCode -eq 0
    }
    catch {
        Write-Host "Error executing command: $_" -ForegroundColor Red
        return $false
    }
}

function Enable-XpCmdshell {
    [CmdletBinding()]
    param()
    
    Write-Host "Enabling xp_cmdshell..." -ForegroundColor Cyan
    try {
        # Enable advanced options first
        Invoke-Sqlcmd -ServerInstance $Server -Database "master" -Username $Username -Password $Password `
            -Query "sp_configure 'show advanced options', 1; RECONFIGURE;" -TrustServerCertificate

        # Then enable xp_cmdshell
        Invoke-Sqlcmd -ServerInstance $Server -Database "master" -Username $Username -Password $Password `
            -Query "sp_configure 'xp_cmdshell', 1; RECONFIGURE;" -TrustServerCertificate
    }
    catch {
        Write-Host "Failed to enable xp_cmdshell: $_" -ForegroundColor Red
        throw
    }
}

function Initialize-TestEnvironment {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Initializing Test Environment ===" -ForegroundColor Yellow
    
    Enable-XpCmdshell
    
    $setupQueries = @"
-- Create test database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SQLHellTest')
BEGIN
    CREATE DATABASE SQLHellTest;
END
GO

USE SQLHellTest;
GO

-- Create test tables
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    CREATE TABLE dbo.Customers (
        CustomerID INT PRIMARY KEY,
        CustomerName NVARCHAR(100),
        CustomerData NVARCHAR(MAX)
    );
    
    -- Add some test data
    INSERT INTO dbo.Customers (CustomerID, CustomerName, CustomerData)
    VALUES (1, 'Test Customer', 'Sensitive Data Here');
END
GO

-- Create test user if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'testuser')
BEGIN
    CREATE LOGIN testuser WITH PASSWORD = 'TestPass123!';
END
GO

-- Create test stored procedures
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_makewebtask]') AND type in (N'P'))
BEGIN
    EXEC('CREATE PROCEDURE dbo.sp_makewebtask
        @outputfile NVARCHAR(255),
        @query NVARCHAR(MAX)
    AS
    BEGIN
        SELECT ''Mock web task execution'' AS Result;
    END');
END
GO

-- Create mock backup history if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[backuphistory]'))
BEGIN
    CREATE TABLE dbo.backuphistory (
        backup_id INT PRIMARY KEY,
        database_name NVARCHAR(128),
        backup_start_date DATETIME,
        backup_finish_date DATETIME
    );
    
    INSERT INTO dbo.backuphistory 
    VALUES (1, 'master', GETDATE(), GETDATE());
END
GO

-- Create a test file for bulk insert
EXEC xp_cmdshell 'echo CustomerID,CustomerName > C:\Temp\customers.csv';
EXEC xp_cmdshell 'echo 1,TestCustomer >> C:\Temp\customers.csv';
"@

    try {
        Write-Host "Creating test database and objects..." -ForegroundColor Cyan
        Invoke-Sqlcmd -ServerInstance $Server -Database "master" -Username $Username -Password $Password `
            -Query $setupQueries -TrustServerCertificate
        
        Write-Host "Test environment initialized successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to initialize test environment: $_" -ForegroundColor Red
        throw
    }
}

$QuerySets = @{
    BasicTests = @{
        Version = "SELECT @@VERSION AS Version"
        Time = "SELECT GETDATE() AS ServerTime"
        Identity = "SELECT SYSTEM_USER AS CurrentUser, SERVERPROPERTY('MachineName') AS MachineName"
    }
    
    SystemInfo = @{
        ServerProperties = @"
SELECT 
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('Collation') AS Collation
"@
        DatabaseSizes = @"
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    CAST(SUM(size) * 8. / 1024 AS DECIMAL(8,2)) AS SizeMB
FROM sys.master_files
GROUP BY database_id
ORDER BY SUM(size) DESC
"@
    }
    
    Security = @{
        Principals = "SELECT name, type_desc, create_date FROM sys.server_principals WHERE type_desc NOT LIKE '%CERTIFICATE%'"
        Permissions = "SELECT * FROM fn_my_permissions(NULL, 'SERVER')"
    }

    SystemEnumeration = @{
        SysObjects = "SELECT * FROM sys.objects"
        ServerInfo = "SELECT @@SERVERNAME, @@VERSION"
        Permissions = "SELECT * FROM fn_my_permissions(NULL, 'SERVER')"
    }
    
    DataExfiltration = @{
        XmlOutput = "SELECT name, type FROM sys.objects FOR XML AUTO"
        JsonOutput = "SELECT name, type FROM sys.objects FOR JSON AUTO"
        SelectInto = "SELECT name, type INTO #temp FROM sys.objects"
    }
    
    ConfigurationTests = @{
        ShowAdvanced = "sp_configure 'show advanced options', 1; RECONFIGURE"
        EnableXpCmdshell = "sp_configure 'xp_cmdshell', 1; RECONFIGURE"
    }
}

Write-Host "=== Atomic Test Methods ===" -ForegroundColor Yellow

Write-Host "Basic Queries:" -ForegroundColor Cyan
Run-SqlCommand @"
`$ErrorActionPreference = 'Continue'
Write-Host 'Running: Basic version query'
Invoke-Sqlcmd -ServerInstance '$Server' -Database '$Database' -Username '$Username' -Password '$Password' -Query 'SELECT @@version' -TrustServerCertificate
"@

Write-Host "Authentication Patterns:" -ForegroundColor Cyan
Run-SqlCommand @"
`$ErrorActionPreference = 'Continue'
Write-Host 'Running: Authentication test'
Invoke-Sqlcmd -ServerInstance '$Server' -Database '$Database' -Username '$Username' -Password '$Password' -Query 'SELECT SYSTEM_USER AS CurrentUser' -TrustServerCertificate
"@

Write-Host "Output Formats:" -ForegroundColor Cyan
Run-SqlCommand @"
`$ErrorActionPreference = 'Continue'
Write-Host 'Running: DataSet output test'
Invoke-Sqlcmd -ServerInstance '$Server' -Database '$Database' -Username '$Username' -Password '$Password' -Query 'SELECT name, database_id FROM sys.databases' -OutputAs DataSet -TrustServerCertificate
"@

Write-Host "System Enumeration:" -ForegroundColor Cyan
Run-SqlCommand @"
`$ErrorActionPreference = 'Continue'
Write-Host 'Running: System principals query'
Invoke-Sqlcmd -ServerInstance '$Server' -Database '$Database' -Username '$Username' -Password '$Password' -Query 'SELECT name, type_desc FROM sys.server_principals' -TrustServerCertificate
"@

Write-Host "`n=== Dual Method Tests ===" -ForegroundColor Yellow

function Test-XpCmdshell {
    [CmdletBinding()]
    param (
        [ValidateSet('Invoke-Sqlcmd', 'sqlcmd.exe')]
        [string]$Method
    )
    
    try {
        Write-Host "`n=== Testing xp_cmdshell ===" -ForegroundColor Yellow
        
        # Step 1: Show advanced options
        Write-Host "Enabling advanced options..." -ForegroundColor Cyan
        if ($Method -eq 'sqlcmd.exe') {
            & sqlcmd -S $Server -d $Database -U $Username -P $Password -Q "sp_configure 'show advanced options', 1; RECONFIGURE;" -b
        } else {
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $Username -Password $Password `
                -Query "sp_configure 'show advanced options', 1; RECONFIGURE;" -TrustServerCertificate
        }
        
        # Step 2: Enable xp_cmdshell
        Write-Host "Enabling xp_cmdshell..." -ForegroundColor Cyan
        if ($Method -eq 'sqlcmd.exe') {
            & sqlcmd -S $Server -d $Database -U $Username -P $Password -Q "sp_configure 'xp_cmdshell', 1; RECONFIGURE;" -b
        } else {
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $Username -Password $Password `
                -Query "sp_configure 'xp_cmdshell', 1; RECONFIGURE;" -TrustServerCertificate
        }
        
        # Step 3: Test xp_cmdshell
        Write-Host "Testing xp_cmdshell execution..." -ForegroundColor Cyan
        if ($Method -eq 'sqlcmd.exe') {
            & sqlcmd -S $Server -d $Database -U $Username -P $Password -Q "EXEC xp_cmdshell 'whoami'" -b
        } else {
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $Username -Password $Password `
                -Query "EXEC xp_cmdshell 'whoami'" -TrustServerCertificate
        }
        
        # Step 4: Disable xp_cmdshell
        Write-Host "Disabling xp_cmdshell..." -ForegroundColor Cyan
        if ($Method -eq 'sqlcmd.exe') {
            & sqlcmd -S $Server -d $Database -U $Username -P $Password -Q "sp_configure 'xp_cmdshell', 0; RECONFIGURE;" -b
        } else {
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $Username -Password $Password `
                -Query "sp_configure 'xp_cmdshell', 0; RECONFIGURE;" -TrustServerCertificate
        }
        
        # Step 5: Hide advanced options
        Write-Host "Disabling advanced options..." -ForegroundColor Cyan
        if ($Method -eq 'sqlcmd.exe') {
            & sqlcmd -S $Server -d $Database -U $Username -P $Password -Q "sp_configure 'show advanced options', 0; RECONFIGURE;" -b
        } else {
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $Username -Password $Password `
                -Query "sp_configure 'show advanced options', 0; RECONFIGURE;" -TrustServerCertificate
        }
        
        Write-Host "xp_cmdshell test completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "xp_cmdshell test failed: $_" -ForegroundColor Red
    }
}

function Invoke-SqlTest {
    param (
        [string]$Query,
        [string]$Description,
        [ValidateSet('Invoke-Sqlcmd', 'sqlcmd.exe')]
        [string]$Method
    )
    
    Write-Host "`nExecuting: $Description using $Method" -ForegroundColor Cyan
    try {
        if ($Method -eq 'sqlcmd.exe') {
            & sqlcmd -S $Server -d $Database -U $Username -P $Password -Q $Query -b
            Write-Host "Test completed successfully" -ForegroundColor Green
            return $true
        } else {
            Invoke-Sqlcmd -ServerInstance $Server -Database $Database -Username $Username -Password $Password `
                -Query $Query -TrustServerCertificate
            Write-Host "Test completed successfully" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Test failed: $_" -ForegroundColor Red
        return $false
    }
}

function Test-SqlRequirements {
    [CmdletBinding()]
    param()
    
    $requirements = @{
        'Invoke-Sqlcmd' = $false
        'sqlcmd.exe' = $false
    }
    
    # Check for Invoke-Sqlcmd
    if (Get-Command 'Invoke-Sqlcmd' -ErrorAction SilentlyContinue) {
        $requirements['Invoke-Sqlcmd'] = $true
        Write-Host "Found Invoke-Sqlcmd cmdlet" -ForegroundColor Green
    } else {
        Write-Host "Invoke-Sqlcmd not found. Install SqlServer module with: Install-Module -Name SqlServer -Force" -ForegroundColor Yellow
    }
    
    # Check for sqlcmd.exe
    if (Get-Command 'sqlcmd' -ErrorAction SilentlyContinue) {
        $requirements['sqlcmd.exe'] = $true
        Write-Host "Found sqlcmd.exe" -ForegroundColor Green
    } else {
        Write-Host "sqlcmd.exe not found. Install SQL Server Command Line Utilities" -ForegroundColor Yellow
    }
    
    # If neither is available, exit
    if (-not ($requirements['Invoke-Sqlcmd'] -or $requirements['sqlcmd.exe'])) {
        Write-Host "Neither Invoke-Sqlcmd nor sqlcmd.exe found. Please install at least one of them." -ForegroundColor Red
        exit 1
    }
    
    # If UseBothMethods is true but one is missing, warn user
    if ($UseBothMethods -and -not ($requirements['Invoke-Sqlcmd'] -and $requirements['sqlcmd.exe'])) {
        Write-Host "Warning: UseBothMethods is set but not all tools are available. Will use available tools only." -ForegroundColor Yellow
        $script:UseBothMethods = $false
    }
    
    return $requirements
}

function Test-UrlInput {
    param($Method)
    
    $queries = @(
        "SELECT * FROM sys.objects; -- https://example.com/data.csv",
        "SELECT * FROM sys.server_principals; -- ftp://example.com/data.csv",
        "DECLARE @url VARCHAR(100) = 'https://example.com/query.sql'"
    )
    
    foreach ($query in $queries) {
        Invoke-SqlTest -Query $query -Description "URL Input Test" -Method $Method
    }
}

function Test-OutputPatterns {
    param($Method)
    
    $queries = @(
        "SELECT * FROM sys.objects; -- Output: C:\temp\output.txt",
        "BACKUP DATABASE master TO DISK = 'C:\temp\master.bak'",
        "SELECT * INTO #temp FROM sys.server_principals; -- C:\Users\Public\admins.csv"
    )
    
    foreach ($query in $queries) {
        Invoke-SqlTest -Query $query -Description "Output Pattern Test" -Method $Method
    }
}

try {
    Write-Host "Starting SQL Server tests..." -ForegroundColor Cyan
    
    $availableTools = Test-SqlRequirements
    
    foreach ($setName in $QuerySets.Keys) {
        Write-Host "`n=== $setName ===" -ForegroundColor Yellow
        
        foreach ($testName in $QuerySets[$setName].Keys) {
            $query = $QuerySets[$setName][$testName]
            
            if ($availableTools['Invoke-Sqlcmd']) {
                Invoke-SqlTest -Query $query -Description $testName -Method 'Invoke-Sqlcmd'
            }
            
            if ($UseBothMethods -and $availableTools['sqlcmd.exe']) {
                Invoke-SqlTest -Query $query -Description $testName -Method 'sqlcmd.exe'
            }
        }
    }

    if ($availableTools['Invoke-Sqlcmd']) {
        Test-XpCmdshell -Method 'Invoke-Sqlcmd'
    }
    if ($UseBothMethods -and $availableTools['sqlcmd.exe']) {
        Test-XpCmdshell -Method 'sqlcmd.exe'
    }

    if ($availableTools['Invoke-Sqlcmd']) {
        Test-UrlInput -Method 'Invoke-Sqlcmd'
    }
    if ($UseBothMethods -and $availableTools['sqlcmd.exe']) {
        Test-UrlInput -Method 'sqlcmd.exe'
    }

    if ($availableTools['Invoke-Sqlcmd']) {
        Test-OutputPatterns -Method 'Invoke-Sqlcmd'
    }
    if ($UseBothMethods -and $availableTools['sqlcmd.exe']) {
        Test-OutputPatterns -Method 'sqlcmd.exe'
    }

    Write-Host "`n=== Testing Data Exfiltration Patterns ===" -ForegroundColor Yellow
    Test-UrlInput -Method 'Invoke-Sqlcmd'
    Test-OutputPatterns -Method 'Invoke-Sqlcmd'
    
    if ($UseBothMethods) {
        Test-UrlInput -Method 'sqlcmd.exe'
        Test-OutputPatterns -Method 'sqlcmd.exe'
    }

    Write-Host "`nAll tests completed!" -ForegroundColor Green
}
catch {
    Write-Host "Script execution failed: $_" -ForegroundColor Red
    exit 1
}