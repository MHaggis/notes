<#
.SYNOPSIS
    SQL Server Verification Tester

.DESCRIPTION
    This script verifies basic SQL Server connectivity and functionality.
    It checks if the SQL Server service is running, loads necessary assemblies,
    and executes a simple query to confirm the connection.

.PARAMETER Server
    The SQL Server instance to test (default: localhost)

.PARAMETER Database
    The database to connect to (default: master)

.PARAMETER SAPassword
    SQL Server sa account password (default: ComplexPass123!)

.EXAMPLE
    # Basic usage with default parameters
    .\sql-tester.ps1

.EXAMPLE
    # Test a remote SQL Server
    .\sql-tester.ps1 -Server "sql.contoso.com" -SAPassword "SecurePass123!"

.NOTES
    File Name      : sql-tester.ps1
    Author         : The Haag
    Prerequisite   : PowerShell 5.1 or later
                    SQL Server assemblies
    
    WARNING: This tool is for authorized security testing only. 
    Improper use could cause system instability or security issues.

.LINK
    https://github.com/MHaggis/notes/tree/master/utilities/SQLSSTT
#>


$ErrorActionPreference = "Continue"
$server = "localhost"
$database = "master"
$saPassword = "ComplexPass123!" 

try {
    Add-Type -AssemblyName "System.Data, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
    Write-Host "SQL Server assemblies loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "Error loading SQL Server assemblies: $_" -ForegroundColor Red
    exit 1
}

# Verify SQL Server service is running
$sqlService = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
if ($sqlService.Status -ne 'Running') {
    Write-Host "SQL Server service is not running. Starting service..." -ForegroundColor Yellow
    Start-Service -Name "MSSQLSERVER"
    Start-Sleep -Seconds 5
}

function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Test-SqlConnection {
    param([string]$Query, [string]$Description)
    try {
        Write-Host "Testing: $Description" -ForegroundColor Yellow
        
        $connectionString = "Server=$server;Database=$database;User ID=sa;Password=$saPassword;TrustServerCertificate=True"
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $command = New-Object System.Data.SqlClient.SqlCommand($Query, $connection)
        
        $connection.Open()
        $reader = $command.ExecuteReader()
        
        $table = New-Object System.Data.DataTable
        $table.Load($reader)
        
        Write-Host "Success!" -ForegroundColor Green
        
        $table | Format-Table -AutoSize
        
        return $table
    }
    catch {
        Write-Host "Failed: $_" -ForegroundColor Red
        return $null
    }
    finally {
        if ($reader) { $reader.Close() }
        if ($connection) { $connection.Close() }
    }
}

Write-TestHeader "Basic Connectivity"
Test-SqlConnection -Query "SELECT @@VERSION AS Version" -Description "Server Version"
Test-SqlConnection -Query "SELECT GETDATE() AS CurrentTime" -Description "Current Time"

Write-TestHeader "Database Enumeration"
Test-SqlConnection -Query "SELECT name, database_id, create_date FROM sys.databases" `
                  -Description "List Databases"

Write-TestHeader "User Permissions"
Test-SqlConnection -Query "SELECT SYSTEM_USER AS CurrentUser" -Description "Current User"
Test-SqlConnection -Query "SELECT name, type_desc FROM sys.server_principals WHERE type IN ('S', 'U')" `
                  -Description "SQL Logins"

Write-TestHeader "Server Configuration"
Test-SqlConnection -Query @"
SELECT name, value, value_in_use, description 
FROM sys.configurations 
WHERE name IN ('max degree of parallelism', 'max server memory (MB)', 'min server memory (MB)')
"@ -Description "Important Settings"

Write-TestHeader "Database Sizes"
Test-SqlConnection -Query @"
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    CAST(SUM(size) * 8. / 1024 AS DECIMAL(8,2)) AS SizeMB
FROM sys.master_files
GROUP BY database_id
"@ -Description "Database Sizes"

Write-TestHeader "Active Connections"
Test-SqlConnection -Query @"
SELECT 
    DB_NAME(dbid) AS DatabaseName,
    COUNT(dbid) AS NumberOfConnections,
    loginame AS LoginName
FROM sys.sysprocesses
WHERE dbid > 0
GROUP BY dbid, loginame
"@ -Description "Current Connections"

Write-TestHeader "Server Properties"
Test-SqlConnection -Query @"
SELECT 
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('Collation') AS Collation
"@ -Description "Server Properties"

Write-Host "`nTest script completed!" -ForegroundColor Green